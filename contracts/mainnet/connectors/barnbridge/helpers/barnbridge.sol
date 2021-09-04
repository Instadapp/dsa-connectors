abstract contract BarnBridgeHelpers {

    
    // buy at least _minTokens with _underlyingAmount, before _deadline passes
    function buyTokens(
      uint256 underlyingAmount_,
      uint256 minTokens_,
      uint256 deadline_
    )
      external override
    {
        _beforeProviderOp(block.timestamp);

        require(
          false == IController(controller).PAUSED_BUY_JUNIOR_TOKEN(),
          "SY: buyTokens paused"
        );

        require(
          block.timestamp <= deadline_,
          "SY: buyTokens deadline"
        );

        uint256 fee = MathUtils.fractionOf(underlyingAmount_, IController(controller).FEE_BUY_JUNIOR_TOKEN());
        // (underlyingAmount_ - fee) * EXP_SCALE / price()
        uint256 getsTokens = (underlyingAmount_.sub(fee)).mul(EXP_SCALE).div(price());

        require(
          getsTokens >= minTokens_,
          "SY: buyTokens minTokens"
        );

        // ---

        address buyer = msg.sender;

        IProvider(pool)._takeUnderlying(buyer, underlyingAmount_);
        IProvider(pool)._depositProvider(underlyingAmount_, fee);
        _mint(buyer, getsTokens);

        emit BuyTokens(buyer, underlyingAmount_, getsTokens, fee);
    }
    
    // sell _tokens for at least _minUnderlying, before _deadline and forfeit potential future gains
    function sellTokens(
      uint256 tokenAmount_,
      uint256 minUnderlying_,
      uint256 deadline_
    )
      external override
    {
        _beforeProviderOp(block.timestamp);

        require(
          block.timestamp <= deadline_,
          "SY: sellTokens deadline"
        );

        // share of these tokens in the debt
        // tokenAmount_ * EXP_SCALE / totalSupply()
        uint256 debtShare = tokenAmount_.mul(EXP_SCALE).div(totalSupply());
        // (abondDebt() * debtShare) / EXP_SCALE
        uint256 forfeits = abondDebt().mul(debtShare).div(EXP_SCALE);
        // debt share is forfeit, and only diff is returned to user
        // (tokenAmount_ * price()) / EXP_SCALE - forfeits
        uint256 toPay = tokenAmount_.mul(price()).div(EXP_SCALE).sub(forfeits);

        require(
          toPay >= minUnderlying_,
          "SY: sellTokens minUnderlying"
        );

        // ---

        address seller = msg.sender;

        _burn(seller, tokenAmount_);
        IProvider(pool)._withdrawProvider(toPay, 0);
        IProvider(pool)._sendUnderlying(seller, toPay);

        emit SellTokens(seller, tokenAmount_, toPay, forfeits);
    }

    // Purchase a senior bond with principalAmount_ underlying for forDays_, buyer gets a bond with gain >= minGain_ or revert. deadline_ is timestamp before which tx is not rejected.
    // returns gain
    function buyBond(
        uint256 principalAmount_,
        uint256 minGain_,
        uint256 deadline_,
        uint16 forDays_
    )
      external override
      returns (uint256)
    {
        _beforeProviderOp(block.timestamp);

        require(
          false == IController(controller).PAUSED_BUY_SENIOR_BOND(),
          "SY: buyBond paused"
        );

        require(
          block.timestamp <= deadline_,
          "SY: buyBond deadline"
        );

        require(
            0 < forDays_ && forDays_ <= IController(controller).BOND_LIFE_MAX(),
            "SY: buyBond forDays"
        );

        uint256 gain = bondGain(principalAmount_, forDays_);

        require(
          gain >= minGain_,
          "SY: buyBond minGain"
        );

        require(
          gain > 0,
          "SY: buyBond gain 0"
        );

        require(
          gain < underlyingLoanable(),
          "SY: buyBond underlyingLoanable"
        );

        uint256 issuedAt = block.timestamp;

        // ---

        address buyer = msg.sender;

        IProvider(pool)._takeUnderlying(buyer, principalAmount_);
        IProvider(pool)._depositProvider(principalAmount_, 0);

        SeniorBond memory b =
            SeniorBond(
                principalAmount_,
                gain,
                issuedAt,
                uint256(1 days) * uint256(forDays_) + issuedAt,
                false
            );

        _mintBond(buyer, b);

        emit BuySeniorBond(buyer, seniorBondId, principalAmount_, gain, forDays_);

        return gain;
    }

    // buy an nft with tokenAmount_ jTokens, that matures at abond maturesAt
    function buyJuniorBond(
      uint256 tokenAmount_,
      uint256 maxMaturesAt_,
      uint256 deadline_
    )
      external override
    {
        _beforeProviderOp(block.timestamp);

        // 1 + abond.maturesAt / EXP_SCALE
        uint256 maturesAt = abond.maturesAt.div(EXP_SCALE).add(1);

        require(
          block.timestamp <= deadline_,
          "SY: buyJuniorBond deadline"
        );

        require(
          maturesAt <= maxMaturesAt_,
          "SY: buyJuniorBond maxMaturesAt"
        );

        JuniorBond memory jb = JuniorBond(
          tokenAmount_,
          maturesAt
        );

        // ---

        address buyer = msg.sender;

        _takeTokens(buyer, tokenAmount_);
        _mintJuniorBond(buyer, jb);

        emit BuyJuniorBond(buyer, juniorBondId, tokenAmount_, maturesAt);

        // if abond.maturesAt is past we can liquidate, but juniorBondsMaturingAt might have already been liquidated
        if (block.timestamp >= maturesAt) {
            JuniorBondsAt memory jBondsAt = juniorBondsMaturingAt[jb.maturesAt];

            if (jBondsAt.price == 0) {
                _liquidateJuniorsAt(jb.maturesAt);
            } else {
                // juniorBondsMaturingAt was previously liquidated,
                _burn(address(this), jb.tokens); // burns user's locked tokens reducing the jToken supply
                // underlyingLiquidatedJuniors += jb.tokens * jBondsAt.price / EXP_SCALE
                underlyingLiquidatedJuniors = underlyingLiquidatedJuniors.add(
                  jb.tokens.mul(jBondsAt.price).div(EXP_SCALE)
                );
                _unaccountJuniorBond(jb);
            }
            return this.redeemJuniorBond(juniorBondId);
        }
    }


    // Redeem a senior bond by it's id. Anyone can redeem but owner gets principal + gain
    function redeemBond(
      uint256 bondId_
    )
      external override
    {
        _beforeProviderOp(block.timestamp);

        require(
            block.timestamp >= seniorBonds[bondId_].maturesAt,
            "SY: redeemBond not matured"
        );

        // bondToken.ownerOf will revert for burned tokens
        address payTo = IBond(seniorBond).ownerOf(bondId_);
        // seniorBonds[bondId_].gain + seniorBonds[bondId_].principal
        uint256 payAmnt = seniorBonds[bondId_].gain.add(seniorBonds[bondId_].principal);
        uint256 fee = MathUtils.fractionOf(seniorBonds[bondId_].gain, IController(controller).FEE_REDEEM_SENIOR_BOND());
        payAmnt = payAmnt.sub(fee);

        // ---

        if (seniorBonds[bondId_].liquidated == false) {
            seniorBonds[bondId_].liquidated = true;
            _unaccountBond(seniorBonds[bondId_]);
        }

        // bondToken.burn will revert for already burned tokens
        IBond(seniorBond).burn(bondId_);

        IProvider(pool)._withdrawProvider(payAmnt, fee);
        IProvider(pool)._sendUnderlying(payTo, payAmnt);

        emit RedeemSeniorBond(payTo, bondId_, fee);
    }

}