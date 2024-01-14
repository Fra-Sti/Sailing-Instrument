using Toybox.Application;
using Toybox.System;
using Toybox.Timer;

class UltrasonicApp extends Application.AppBase {

    hidden var _controller;
    hidden var _model;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {

        // Create configuration data, if necessary
        if (self.Properties.getValue("Hz") == null) {
        	self.Properties.setProperty("WindRose", false);
            self.Properties.setProperty("WindSpeed", false);
            self.Properties.setProperty("WindUnit", false);
            self.Properties.setProperty("Hz", false);
        }

        //Create, configure and start the Calypso class
        _model = new CalypsoModel();

        _model.enableOptSensors(true);
        if (self.Properties.getValue("Hz") == true) {_model.setDataRate(4);} 
        else {_model.setDataRate(1);}

        _model.onStart();

        // Create and run BehaviorDelegate that manages events
        _controller = new UltrasonicController(_model, self);
        _controller.onStart();
    }
    
    function onPosition(pos) {
    	// do something with GPS data here, or not
    }

    function onStop(state) {
        _controller.onStop();
        _controller = null;

        _model.onStop();
        _model = null;
    }
    
    function getInitialView() {
       return _controller.getInitialView();
    }
}