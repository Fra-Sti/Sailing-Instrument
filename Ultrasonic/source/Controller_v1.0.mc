using Toybox.Application;
using Toybox.WatchUi;
using Toybox.System;
using Toybox.BluetoothLowEnergy as Ble;


class UltrasonicController extends WatchUi.BehaviorDelegate
{
    hidden var _view;
    hidden var _model;
    hidden var _app;

    function initialize(model, app) {
        BehaviorDelegate.initialize();
        _model = model;
        _app = app;
    }
	
    function onStart() {
        Ble.setDelegate(_model); 
    }
	
    function onStop() {
    }
    
    function getInitialView() {
        _view = new UltrasonicView(_model, _app);
        return [ _view, self ];
    }

}
