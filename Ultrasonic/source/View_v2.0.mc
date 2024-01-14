import Toybox.Application;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Math;
using Toybox.FitContributor as Fit;
using Toybox.Activity as Activity;

var WIND_UNIT = "kt";
var WIND_FACTOR = 1.9438444924574;

class UltrasonicView extends WatchUi.DataField
{
	hidden var _model;
	hidden var _app;
    hidden var _xpos;
    hidden var _font;
	hidden var _font_small;
    hidden var _font_medium;
    hidden var _font_large;
    hidden var _ljust;
    hidden var _rjust;
    hidden var _cjust;
	hidden var _lineHeight_small;
    hidden var _lineHeight;
    hidden var _lineHeight_medium;
    hidden var _lineHeight_large;
    hidden var _viewHeight;
    hidden var _viewWidth;

    hidden var field = [0, 0, 0];

    hidden var count = 0;
	hidden var x0;
    hidden var y0; 
    
    hidden var _ultrasonicFitField_TWS;
    hidden var _ultrasonicFitField_TWA;
    hidden var _ultrasonicFitField_AWS;
    hidden var _ultrasonicFitField_AWA;
    
    hidden var SOG = 0;
    hidden var COG = 0;
    hidden var TWS = 0;
    hidden var TWD = 0;
    hidden var AWS = 0;
	hidden var AWD = 0; 
    
    //Cached data to save battery
    hidden var f_cos = [Math.cos(-60 / 57.2957), 
    					Math.cos(-30 / 57.2957), 
    					Math.cos(0   / 57.2957), 
    					Math.cos(30  / 57.2957), 
    					Math.cos(60  / 57.2957), 
    					Math.cos(90  / 57.2957), 
    					Math.cos(120 / 57.2957), 
    					Math.cos(150 / 57.2957), 
    					Math.cos(180 / 57.2957), 
    					Math.cos(210 / 57.2957), 
    					Math.cos(240 / 57.2957), 
    					Math.cos(270 / 57.2957)];
    hidden var f_sin = [Math.sin(-60 / 57.2957), 
    					Math.sin(-30 / 57.2957), 
    					Math.sin(0   / 57.2957), 
    					Math.sin(30  / 57.2957), 
    					Math.sin(60  / 57.2957), 
    					Math.sin(90  / 57.2957), 
    					Math.sin(120 / 57.2957), 
    					Math.sin(150 / 57.2957), 
    					Math.sin(180 / 57.2957), 
    					Math.sin(210 / 57.2957), 
    					Math.sin(240 / 57.2957), 
    					Math.sin(270 / 57.2957)];
    

    function initialize(model, app) {
        DataField.initialize();
        _model = model;
        _app = app;

		//creating FIT file fields
		_ultrasonicFitField_TWS = createField("TWS", 0, Fit.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>WIND_UNIT });
		_ultrasonicFitField_TWA = createField("TWA", 1, Fit.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"degree" });	
    	_ultrasonicFitField_AWS = createField("AWS", 2, Fit.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>WIND_UNIT });
		_ultrasonicFitField_AWA = createField("AWA", 3, Fit.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"degree" });
	
		//Apply Datafield settings
        if (app.Properties.getValue("WindRose") == true)  { field[0] = 1; }
		if (app.Properties.getValue("WindSpeed") == true) { field[1] = 1; }
		if (app.Properties.getValue("WindUnit") == true)  { field[2] = 1; }
	}   
    

    function onLayout(dc as Dc) { 
    	// Precalculated watch specific results
        _xpos = dc.getWidth() / 3;
		x0 = dc.getWidth() / 2;
        y0 = dc.getHeight() / 2; 

        _font = Graphics.FONT_SYSTEM_XTINY ;
        _lineHeight = dc.getFontHeight(_font);

		_font_small = Graphics.FONT_SMALL;
		_lineHeight_small = dc.getFontHeight(_font_small);
        
        _font_medium = Graphics.FONT_NUMBER_MILD;
        _lineHeight_medium = dc.getFontHeight(_font_medium);
        
        _font_large = Graphics.FONT_NUMBER_THAI_HOT;
        _lineHeight_large = dc.getFontHeight(_font_large);
         
        _ljust = Graphics.TEXT_JUSTIFY_LEFT;
        _rjust = Graphics.TEXT_JUSTIFY_RIGHT;
        _cjust = Graphics.TEXT_JUSTIFY_CENTER;

        _viewHeight = dc.getHeight();
        _viewWidth = dc.getWidth();
    }


	// called once a second by system, or manually after new BLE data
    function onUpdate(dc as Dc) as Void {
		var WS;
		var VMG = 0;
		var NBD = 0;

		var _color;
    	
		var batt = 0;
		//var temp = null;
		var roll = null;
		//var pitch = null;
		//var compass = null ;

		///////////////////////
		// Data receipt      //
		///////////////////////

		if (self.getBackgroundColor() == Graphics.COLOR_BLACK) {
			_color = Graphics.COLOR_WHITE;
			dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
		} else {
			_color = Graphics.COLOR_BLACK;
			dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
		}

		dc.clear();

		// BLE status
		var isScanning = _model.isScanning();
		var scanResults = _model.getSensorData();

		/////////////////////////////////////////////////////////
		// Activate for debugging                              //
		// scanResults = [582, 0, 48, 0, 10, 131, 136, 0, 0, 0];//
		// SOG = 3;                                            //
		/////////////////////////////////////////////////////////
	
		// While not connected to watch display this START SCREEN
		if (scanResults.size() == 0) {	
			var text = "connecting...";
			
			if (isScanning == true) {
				text = "searching...";
			} 
			
			//draw App icon 
			dc.setColor(0x2770CA, Graphics.COLOR_TRANSPARENT);
			dc.setPenWidth(3);
			dc.drawRectangle(_viewWidth * 0.37, _viewHeight * 0.37, _viewWidth * 0.26, _viewHeight * 0.26);
			var pts = [[_viewWidth * 0.5, _viewHeight * 0.5 - 1], 
						[_viewWidth * 0.37 + 6, _viewHeight * 0.63 - 6],
						[_viewWidth * 0.63 - 6, _viewHeight * 0.63 - 6]];
			dc.fillPolygon(pts);
			
			// draw BLE status
			dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
			dc.drawText(x0, _viewHeight * 0.7, _font, text, _cjust);
			return; 
		} 
		
		//Parsing  BLE receiving data
		if (scanResults.size() == 10) {
        	AWS = (scanResults[1] << 8 | scanResults[0]) * 0.01;
			AWD  = (scanResults[3] << 8 | scanResults[2]); 
			batt = scanResults[4];
			//temp = scanResults[5] - 100;
			roll = scanResults[6] - 90;
			//pitch = scanResults[7] - 90;
			//compass  = 360 - (scanResults[9] << 8 | scanResults[8]);
		} 

		///////////////////////
		// Calculations      //
		///////////////////////
		
		// calculate true wind
		if (SOG != 0) {
		
			var ax = AWS * Math.cos( -1 * AWD * Math.PI / 180);
			var ay = AWS * Math.sin( -1 * AWD * Math.PI / 180);
		
			var rx = ax - SOG;
			var ry = ay;
		
			TWD = -1 * Math.atan2(ry, rx) * 180 / Math.PI;
			TWS = Math.sqrt(rx*rx + ry*ry);
			VMG = SOG * Math.cos(TWD * Math.PI / 180);

			if (TWD < 180)  {NBD = 2 * TWD;}
			else {NBD = 2*TWD - 360;}
			
			if (ax == 0 && TWS == 0) {
				TWD = AWD;
				TWS = AWS;
				NBD = TWD;
			}

		} else {
			TWD = AWD;
			TWS = AWS;
			NBD = TWD;
		}	
		
		// Converting wind to knots if field[2] == 0
		// Assign TWS or AWS according to field[1]
		if (field[2] < 1) {
			if (field[1] < 1) {WS = TWS * WIND_FACTOR + 0.5;}
			else {WS = AWS * WIND_FACTOR + 0.5;}
		} else {
			if (field[1] < 1) {WS = TWS + 0.5;}
			else {WS = AWS + 0.5;}
		}
			
		///////////////////////
		// Create page view  //
		///////////////////////

		// Fullscreen
		// https://forums.garmin.com/developer/connect-iq/f/discussion/227787/datafield-get-position-of-the-datafield-on-the-screen-top-half-top-quadrant-on-watch
		if (DataField.getObscurityFlags() == 15) {
			
			// cache math operations
			var i = AWD - 90;
			var sin = Math.sin(i / 57.2957);
			var cos = Math.cos(i / 57.2957);
			
			var j = TWD - 90;
			var sin_t = Math.sin(j / 57.2957);
			var cos_t = Math.cos(j / 57.2957);

			var k = NBD - 90;
			var sin_b = Math.sin(k / 57.2957);
			var cos_b = Math.cos(k / 57.2957);

			var r = x0;
							
			/////////////////////////////////////////////////////////////////////
			//Draw marine instrument
			dc.setPenWidth(14);

			dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
			dc.drawArc(x0, y0,  r -7, Toybox.Graphics.ARC_CLOCKWISE, 70, 30);

			dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
			dc.drawArc(x0, y0, r -7, Toybox.Graphics.ARC_CLOCKWISE, 150, 110);
			
			//Drawing the degree indicators every 30°
			dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
			dc.setPenWidth(2);
			for(i = 0; i <= 10; i++ ) { 
				dc.drawLine(x0 + f_cos[i] * (r - 14),
							y0 + f_sin[i] * (r - 14),
							x0 + f_cos[i] * r,
							y0 + f_sin[i] * r); 
			}

			/////////////////////////////////////////////////////////////////////
			//Writing the Data 
			
			//Wind speed
			dc.drawText(x0, _viewHeight * 0.33 - _lineHeight_large / 2, _font_large, WS.format("%d"), _cjust);
			if (field[1] > 0) {dc.drawText(x0, _lineHeight + 3, _font, "AWS ", _cjust);  
			} else {dc.drawText(x0, _lineHeight + 3, _font, "TWS ", _cjust);}

			//SOG in knots
			dc.drawText((_viewWidth * 0.25)+20 , _viewHeight * 0.66 - _lineHeight_medium / 2 , _font_medium, (SOG * 1.9438).format("%0.1f"), _cjust);
			dc.drawText((_viewWidth * 0.25)+20, _viewHeight * 0.5, _font, "SOG", _cjust);

			//VMG in knots
			dc.drawText((_viewWidth * 0.75)-20, _viewHeight * 0.66 - _lineHeight_medium / 2, _font_medium, (VMG * 1.9438).format("%0.1f"), _cjust);
			dc.drawText((_viewWidth * 0.75)-20, _viewHeight * 0.5, _font, "VMG", _cjust);

			/////////////////////////////////////////////////////////////////////
			//Drawing the Wind Direction Indicator
			dc.setPenWidth(9);
			if (field[0] > 0) {
				//AWA indicator
				dc.drawLine(x0 + cos * (r - 35),
							y0 + sin * (r - 35 ),
							x0 + cos * r,
							y0 + sin * r);
				dc.drawText(x0, 3, _font, "AWD/", _cjust);
			} else {
				//TWA indicator
				dc.drawLine(x0 + cos_t * (r - 35),
							y0 + sin_t * (r - 35 ),
							x0 + cos_t * r,
							y0 + sin_t * r);
				dc.drawText(x0, 3, _font, "TWD/", _cjust);
			}

			
			//Drawing the Tack Assist indicator
			dc.setPenWidth(3);
			dc.drawLine(x0 + cos_b * (r - 35),
						y0 + sin_b * (r - 35),
						x0 + cos_b * r,
						y0 + sin_b * r);

			
			/////////////////////////////////////////////////////////////////////
			//Drawing the roll slider (starting at 6 o'clock = 270°)
			dc.setPenWidth(7);
			
			if (roll > 0) {dc.drawArc(x0, y0, r - 17, Toybox.Graphics.ARC_CLOCKWISE, 270, 270 - roll);} 
			else {dc.drawArc(x0, y0, r - 17, Toybox.Graphics.ARC_CLOCKWISE, 270 - roll, 270);}

			/////////////////////////////////////////////////////////////////////
			//Drawing the Battery indicator
			var delta_x = _lineHeight * 2;
			var delta_y = Math.ceil(delta_x / 2.7);

			dc.setPenWidth(2);
			
			for (i = 0; i < 10; i++) {
				if (batt >= i) {
					dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
				} else {
					dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_TRANSPARENT);
				}
				dc.fillRectangle(x0-delta_x/2 + i*delta_x/10, _viewHeight*0.8, 1+delta_x / 10, delta_y);
			}
			dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
			dc.drawRectangle(x0-delta_x/2, _viewHeight*0.8, 1+delta_x, delta_y);
			dc.drawRectangle(x0+delta_x/2, _viewHeight*0.8 +3, 3, delta_y -6);
			/////////////////////////////////////////////////////////////////////

		} else {
			// Print VMG
			dc.setColor(_color, Graphics.COLOR_TRANSPARENT);

			dc.drawText(x0, y0 - _lineHeight_medium / 2 + _lineHeight/2, _font_medium, VMG.format("%0.1f"), _cjust);
			dc.drawText(x0, 3, _font, "VMG", _cjust);
		}
		return;
	}	
	
	// Called once a second by system 
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
        // See Activity.Info in the documentation for available information.
        if(info has :currentSpeed){
            if(info.currentSpeed != null) {
                SOG = info.currentSpeed;
            } else {
                SOG = 0.0f;
            }
        }
		//writing the wind records to the FIT file every 15 sec
        _ultrasonicFitField_TWS.setData(TWS * WIND_FACTOR);
        _ultrasonicFitField_TWA.setData(TWD);
        _ultrasonicFitField_AWS.setData(AWS * WIND_FACTOR);
        _ultrasonicFitField_AWA.setData(AWD);
    }
}