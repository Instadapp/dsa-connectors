// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { ISuperfluid, IConstantFlowAgreementV1, IInstantDistributionAgreementV1 } from "./interface.sol";
import { CFAv1Library } from "./libraries/CFAv1Library.sol";
import { IDAv1Library } from "./libraries/IDAv1Library.sol";

abstract contract Helpers {
	using CFAv1Library for CFAv1Library.InitData;
	using IDAv1Library for IDAv1Library.InitData;

	ISuperfluid host = ISuperfluid(0x60377C7016E4cdB03C87EF474896C11cB560752C);
	IInstantDistributionAgreementV1 ida =
		IInstantDistributionAgreementV1(
			0x1fA9fFe8Db73F701454B195151Db4Abb18423cf2
		);

	//initialize InitData struct, and set equal to cfaV1
	CFAv1Library.InitData public cfaV1 =
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
