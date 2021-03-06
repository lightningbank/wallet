import 'dart:async';
import 'package:breez/bloc/account/account_actions.dart';
import 'package:breez/bloc/account/account_model.dart';
import 'package:breez/widgets/loader.dart';
import 'package:breez/widgets/payment_failed_report_dialog.dart';
import 'package:flutter/material.dart';
import 'package:breez/bloc/account/account_bloc.dart';
import 'package:breez/bloc/invoice/invoice_model.dart';
import 'package:breez/widgets/payment_request_dialog.dart' as paymentRequest;
import 'package:breez/widgets/flushbar.dart';

class InvoiceNotificationsHandler {
  final BuildContext _context;
  final AccountBloc _accountBloc;
  final Stream<PaymentRequestModel> _receivedInvoicesStream;
  StreamSubscription<String> _sentPaymentResultSubscription;
  ModalRoute _loaderRoute;
  bool _handlingRequest = false;

  InvoiceNotificationsHandler(
      this._context, this._accountBloc, this._receivedInvoicesStream) {
    _listenPaymentRequests();
    _listenPaymentsResults();
  }

  _listenPaymentRequests() {
    _accountBloc.accountStream.where((acc) => acc.active).first.then((acc) {
      // show payment request dialog for decoded requests
      _receivedInvoicesStream
          .where((payreq) => payreq != null && !_handlingRequest)
          .listen((payreq) {
        
        if (!payreq.loaded) {
          _setLoading(true);
          return;
        }

        _setLoading(false);
        _handlingRequest = true;

        showDialog(
                context: _context,
                barrierDismissible: false,
                builder: (_) => paymentRequest.PaymentRequestDialog(
                    _context, _accountBloc, payreq))
            .whenComplete(() => _handlingRequest = false);
      }).onError((error) {
        _setLoading(false);
        _handlingRequest = false;        
      });
    });
  }

  _setLoading(bool visible) {
    if (visible && _loaderRoute == null) {
      _loaderRoute = createLoaderRoute(_context);
      Navigator.of(_context).push(_loaderRoute);
      return;
    }

    if (!visible && _loaderRoute != null) {
      Navigator.removeRoute(_context, _loaderRoute);
      _loaderRoute = null;
    }
  }

  _listenPaymentsResults() {
    AccountSettings accountSettings;

    _accountBloc.accountSettingsStream
        .listen((settings) => accountSettings = settings);

    _sentPaymentResultSubscription =
        _accountBloc.fulfilledPayments.listen((fulfilledPayment) {
      showFlushbar(_context, message: "Payment was successfuly sent!");
    }, onError: (err) => _onPaymentError(accountSettings, err as PaymentError));
  }

  _onPaymentError(AccountSettings accountSettings, PaymentError error) async {
    bool prompt =
        accountSettings.failePaymentBehavior == BugReportBehavior.PROMPT;
    bool send =
        accountSettings.failePaymentBehavior == BugReportBehavior.SEND_REPORT;

    showFlushbar(_context,
        message:
            "Failed to send payment: ${error.toString().split("\n").first}");

    if (!error.validationError) {
      if (prompt) {
        send = await showDialog(
            context: _context,
            barrierDismissible: false,
            builder: (_) =>
                new PaymentFailedReportDialog(_context, _accountBloc));
      }

      if (send) {
        var sendAction = SendPaymentFailureReport(error.traceReport);
        _accountBloc.userActionsSink.add(sendAction);
        await Navigator.push(
            _context,
            createLoaderRoute(_context,
                message: "Sending Report...",
                opacity: 0.8,
                action: sendAction.future));
      }
    }
  }
}
