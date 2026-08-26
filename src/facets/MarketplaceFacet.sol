// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {IFacet} from "@diamond/interfaces/IFacet.sol";
import {IMarketplace} from "@ticket/interfaces/IMarketplace.sol";
import {FeeType, FiatVoucher} from "@ticket/libs/MarketplaceLib.sol";
import {MarketplaceLib} from "@ticket/libs/MarketplaceLib.sol";

contract MarketplaceFacet is IMarketplace, IFacet {
    //*//////////////////////////////////////////////////////////////////////////
    //                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @inheritdoc IMarketplace
    function mintTicket(uint64 _ticketId, FeeType _feeType, address _buyer) external payable returns (uint40) {
        return MarketplaceLib.mintTicket(_ticketId, _feeType, _buyer); // {ticket}
    }

    function updateTicketFees(uint64 _ticketId, FeeType[] calldata _feeTypes, uint256[] calldata _fees) external {
        MarketplaceLib.updateTicketFees(_ticketId, _feeTypes, _fees);
    }

    function claimRefund(uint64 _ticketId, FeeType _feeType, uint256 _tokenId, address _to) external {
        MarketplaceLib.claimRefund(_ticketId, _feeType, _tokenId, _to);
    }

    function withdrawTicketBalance(uint64 _ticketId, FeeType _feeType, address _to) external {
        MarketplaceLib.withdrawTicketBalance(_ticketId, _feeType, _to);
    }

    function withdrawHostItBalance(FeeType _feeType, address _to) external {
        MarketplaceLib.withdrawHostItBalance(_feeType, _to);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                       FIAT PAYMENT — EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @inheritdoc IMarketplace
    function mintFiatTicket(uint64 _ticketId, address _buyer, uint256 _amount, bytes32 _paymentId)
        external
        returns (uint40)
    {
        return MarketplaceLib.mintFiatTicket(_ticketId, _buyer, _amount, _paymentId);
    }

    /// @inheritdoc IMarketplace
    function redeemFiatVoucher(FiatVoucher calldata _v, bytes calldata _signature) external returns (uint40) {
        return MarketplaceLib.redeemFiatVoucher(_v, _signature);
    }

    /// @inheritdoc IMarketplace
    function batchMintFiatTickets(
        uint64[] calldata _ticketIds,
        address[] calldata _buyers,
        uint256[] calldata _amounts,
        bytes32[] calldata _paymentIds
    ) external returns (uint40[] memory) {
        return MarketplaceLib.batchMintFiatTickets(_ticketIds, _buyers, _amounts, _paymentIds);
    }

    /// @inheritdoc IMarketplace
    function batchRedeemFiatVouchers(FiatVoucher[] calldata _vouchers, bytes[] calldata _signatures)
        external
        returns (uint40[] memory)
    {
        return MarketplaceLib.batchRedeemFiatVouchers(_vouchers, _signatures);
    }

    /// @inheritdoc IMarketplace
    function setTrustedBackend(address _backend) external {
        MarketplaceLib.setTrustedBackend(_backend);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    // @return {1}
    function feeEnabled(uint64 _ticketId, FeeType _feeType) external view returns (bool) {
        return MarketplaceLib.feeEnabled(_ticketId, _feeType);
    }

    // @return {addr}
    function getFeeTokenAddress(FeeType _feeType) external view returns (address) {
        return MarketplaceLib.getFeeTokenAddress(_feeType);
    }

    // @return {tok}
    function getTicketFee(uint64 _ticketId, FeeType _feeType) external view returns (uint256) {
        return MarketplaceLib.getTicketFee(_ticketId, _feeType);
    }

    // @return ticketFee_ {tok}, hostItFee_ {tok}, totalFee_ {tok}
    function getAllFees(uint64 _ticketId, FeeType _feeType)
        external
        view
        returns (uint256 ticketFee_, uint256 hostItFee_, uint256 totalFee_)
    {
        return MarketplaceLib.getFees(_ticketId, _feeType);
    }

    // @return {tok}
    function getTicketBalance(uint64 _ticketId, FeeType _feeType) external view returns (uint256) {
        return MarketplaceLib.getTicketBalance(_ticketId, _feeType);
    }

    // @return {tok}
    function getHostItBalance(FeeType _feeType) external view returns (uint256) {
        return MarketplaceLib.getHostItBalance(_feeType);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                         FIAT PAYMENT — VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    /// @inheritdoc IMarketplace
    function getTrustedBackend() external view returns (address) {
        return MarketplaceLib.getTrustedBackend();
    }

    /// @inheritdoc IMarketplace
    function isFiatPaidToken(uint64 _ticketId, uint40 _tokenId) external view returns (bool) {
        return MarketplaceLib.isFiatPaidToken(_ticketId, _tokenId);
    }

    /// @inheritdoc IMarketplace
    function isFiatPaymentIdUsed(bytes32 _paymentId) external view returns (bool) {
        return MarketplaceLib.isFiatPaymentIdUsed(_paymentId);
    }

    /// @inheritdoc IMarketplace
    function getTicketFiatRevenue(uint64 _ticketId) external view returns (uint256) {
        return MarketplaceLib.getTicketFiatRevenue(_ticketId);
    }

    /// @inheritdoc IMarketplace
    function getFiatDomainSeparator() external view returns (bytes32) {
        return MarketplaceLib.getFiatDomainSeparator();
    }

    /// @inheritdoc IMarketplace
    function hashFiatVoucher(FiatVoucher calldata _v) external pure returns (bytes32) {
        return MarketplaceLib.hashFiatVoucher(_v);
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                               PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*//

    // @param _fee {tok} @return {tok}
    function getHostItFee(uint256 _fee) external pure returns (uint256) {
        return MarketplaceLib.getHostItFee(_fee);
    }

    // @return {s}
    function getRefundPeriod() external pure returns (uint256) {
        return MarketplaceLib.REFUND_PERIOD;
    }

    /// @inheritdoc IMarketplace
    function getFiatVoucherTypehash() external pure returns (bytes32) {
        return MarketplaceLib.FIAT_VOUCHER_TYPEHASH;
    }

    function exportSelectors() external pure override returns (bytes memory selectors_) {
        selectors_ = bytes.concat(
            abi.encodePacked(
                this.batchMintFiatTickets.selector,
                this.batchRedeemFiatVouchers.selector,
                this.claimRefund.selector,
                this.feeEnabled.selector,
                this.getAllFees.selector,
                this.getFeeTokenAddress.selector,
                this.getFiatDomainSeparator.selector,
                this.getFiatVoucherTypehash.selector,
                this.getHostItBalance.selector
            ),
            abi.encodePacked(
                this.getHostItFee.selector,
                this.getRefundPeriod.selector,
                this.getTicketBalance.selector,
                this.getTicketFee.selector,
                this.getTicketFiatRevenue.selector,
                this.getTrustedBackend.selector,
                this.hashFiatVoucher.selector,
                this.isFiatPaidToken.selector
            ),
            abi.encodePacked(
                this.isFiatPaymentIdUsed.selector,
                this.mintFiatTicket.selector,
                this.mintTicket.selector,
                this.redeemFiatVoucher.selector,
                this.setTrustedBackend.selector,
                this.updateTicketFees.selector,
                this.withdrawHostItBalance.selector,
                this.withdrawTicketBalance.selector
            )
        );
    }
}
