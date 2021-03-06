import 'package:breez/widgets/transparent_page_route.dart';
import 'package:flutter/material.dart';
import 'package:breez/theme_data.dart' as theme;

class Loader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: FractionalOffset.center, children: <Widget>[
      new CircularProgressIndicator(
        valueColor: new AlwaysStoppedAnimation<Color>(
          theme.circularLoaderColor,
        ),        
      ),
    ]);
  }
}

TransparentPageRoute createLoaderRoute(BuildContext context,
    {String message, double opacity = 0.5, Future action}) {
  return TransparentPageRoute((context) {
    return TransparentRouteLoader(message: message, opacity: opacity, action: action);
  });
}

class FullScreenLoader extends StatelessWidget {
  final String message;
  final double opacity;

  const FullScreenLoader({Key key, this.message, this.opacity = 0.5})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
          color: Colors.black.withOpacity(this.opacity),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Loader(),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: message != null
                    ? Text(message, textAlign: TextAlign.center)
                    : SizedBox(),
              )
            ],
          )),
    );
  }
}

class TransparentRouteLoader extends StatefulWidget {
  final String message;
  final double opacity;
  final Future action;

  const TransparentRouteLoader({Key key, this.message, this.opacity = 0.5, this.action})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {    
    return TransparentRouteLoaderState();
  }
}

class TransparentRouteLoaderState extends State<TransparentRouteLoader> {
  
  @override void initState() {    
    super.initState();
    if (widget.action != null) {
      widget.action.whenComplete((){
        if (this.mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullScreenLoader(message: widget.message, opacity: widget.opacity);
  }
}