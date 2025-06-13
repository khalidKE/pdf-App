import 'package:flutter/material.dart';
import 'package:pdf_utility_pro/utils/constants.dart';
import 'package:lottie/lottie.dart';

class CustomErrorWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final bool showAnimation;
  final bool isFullScreen;
  
  const CustomErrorWidget({
    Key? key,
    required this.message,
    this.details,
    this.onRetry,
    this.showAnimation = true,
    this.isFullScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showAnimation)
          Lottie.asset(
            'assets/animations/error.json',
            width: 200,
            height: 200,
            repeat: true,
          ),
        const SizedBox(height: AppConstants.defaultSpacing * 2),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (details != null) ...[
          const SizedBox(height: AppConstants.defaultSpacing),
          Text(
            details!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: AppConstants.defaultSpacing * 2),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );

    if (isFullScreen) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
            child: content,
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
        child: content,
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final Widget child;
  final Object? error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;
  final bool isFullScreen;
  
  const ErrorScreen({
    Key? key,
    required this.child,
    this.error,
    this.stackTrace,
    this.onRetry,
    this.isFullScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (error == null) {
      return child;
    }

    String message = AppConstants.genericError;
    String? details;

    if (error is String) {
      message = error as String;
    } else if (error != null) {
      message = error.toString();
    }

    if (stackTrace != null) {
      details = stackTrace.toString().split('\n').take(3).join('\n');
    }

    return CustomErrorWidget(
      message: message,
      details: details,
      onRetry: onRetry,
      isFullScreen: isFullScreen,
    );
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;
  final VoidCallback? onError;
  
  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
    this.onError,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });
      widget.onError?.call();
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace ?? StackTrace.current);
      }
      return CustomErrorWidget(
        message: _error.toString(),
        details: _stackTrace?.toString().split('\n').take(3).join('\n'),
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }

    return widget.child;
  }
} 