// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { Basic } from "../../common/basic.sol";
import { ISuperfluid, IConstantFlowAgreementV1, IInstantDistributionAgreementV1 } from "./interface.sol";
import { CFAv1Library } from "./libraries/CFAv1Library.sol";
import { IDAv1Library } from "./libraries/IDAv1Library.sol";

abstract contract Helpers is Basic {
	using CFAv1Library for CFAv1Library.InitData;
	using IDAv1Library for IDAv1Library.InitData;

	ISuperfluid internal constant host =
		ISuperfluid(0x3E14dC1b13c488a8d5D310918780c983bD5982E7);
	IInstantDistributionAgreementV1 internal constant ida =
		IInstantDistributionAgreementV1(
			0xB0aABBA4B2783A72C52956CDEF62d438ecA2d7a1
		);

	//initialize InitData struct, and set equal to cfaV1
	CFAv1Library.InitData internal cfaV1 =
		CFAv1Library.InitData(
			host,
			//here, we are deriving the address of the CFA using the host contract
			IConstantFlowAgreementV1(
				address(
					host.getAgreementClass(
						keccak256(
							"org.superfluid-finance.agreements.ConstantFlowAgreement.v1"
						)
					)
				)
			)
		);

	// declare `_idaLib` of type InitData and assign it the host and ida addresses
	IDAv1Library.InitData internal _idav1Lib = IDAv1Library.InitData(host, ida);
}
