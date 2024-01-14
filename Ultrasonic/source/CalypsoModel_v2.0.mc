///////////////////////////////////////////////////////////////////////////////////////////
// All parameters must be set in App.mc before calling onStart()                         //
// Changing properties / characteristics while running the notifications is not possible //
///////////////////////////////////////////////////////////////////////////////////////////

using Toybox.System;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Attention;


class CalypsoModel extends Ble.BleDelegate
{
    hidden var _scanResults;
    hidden var _scanState;
    hidden var _calypsoData;
 
    hidden var _NOTIFICATION;
    hidden var _DATA_RATE;
    hidden var _PITCH_ENABLED;

    hidden var HighDataRate = false;
    hidden var isCalypsoMini = false;

    hidden var _config_next = 0;
    hidden var _optional_sensors_enabled = false;   //false = OFF, true = ON
    
    public const CALYPSO_DATA_SERVICE = Ble.stringToUuid("0000180D-0000-1000-8000-00805F9B34FB");
    public const WIND_DATA_CHARACTERISTIC = Ble.stringToUuid("00002A39-0000-1000-8000-00805F9B34FB");
    public const DATA_RATE_CHARACTERISTIC = Ble.stringToUuid("0000A002-0000-1000-8000-00805F9B34FB");
    public const PITCH_CHARACTERISTIC = Ble.stringToUuid("0000A003-0000-1000-8000-00805F9B34FB");

    private const _CalypsoProfileDef = {
        :uuid => CALYPSO_DATA_SERVICE,
        :characteristics => [{
            :uuid => WIND_DATA_CHARACTERISTIC,
			:descriptors => [Ble.cccdUuid()]
        },{
        	:uuid => DATA_RATE_CHARACTERISTIC,
			:descriptors => [Ble.cccdUuid()]
        },{
        	:uuid => PITCH_CHARACTERISTIC,
			:descriptors => [Ble.cccdUuid()]
        }]
    };

    function initialize() {
        BleDelegate.initialize();
        registerProfiles();

        _scanResults = [];
        _scanState = Ble.SCAN_STATE_OFF;
        _calypsoData = [];
    }

    function onStart() {
    	Ble.setScanState(Ble.SCAN_STATE_SCANNING);
    }

    function onStop() {
    }
    
    // New BLE device found
    function onScanResults(scanResults) { 
        for (var result = scanResults.next(); result != null; result = scanResults.next()) {
            var name = result.getDeviceName();
            if (name != null) {
                if (name.equals("ULTRASONIC")) {
                        Attention.playTone(Attention.TONE_LAP);
                        Ble.setScanState(Ble.SCAN_STATE_OFF);
					    Ble.pairDevice(result);
                }
            }
        }
    }
    
    function onConnectedStateChanged(device, state) {
		if (state == Ble.CONNECTION_STATE_CONNECTED) {
            var service = device.getService(CALYPSO_DATA_SERVICE );
            _NOTIFICATION = service.getCharacteristic(WIND_DATA_CHARACTERISTIC);
            _DATA_RATE = service.getCharacteristic(DATA_RATE_CHARACTERISTIC);
            _PITCH_ENABLED = service.getCharacteristic(PITCH_CHARACTERISTIC);
            configureCalypso(0);
        } else {
			Ble.setScanState(Ble.SCAN_STATE_SCANNING); 
			_NOTIFICATION = null;
			_DATA_RATE = null;
			_PITCH_ENABLED = null;
			_calypsoData = [];
			WatchUi.requestUpdate();
		}
	}

    // BLE notify event
	function onCharacteristicChanged(char, value) {
		_calypsoData = value;
        if (HighDataRate) {WatchUi.requestUpdate();}
	}

    
    // After BLE write
    function onCharacteristicWrite(characteristic, status) {
  		if (_config_next > 0) {
  		    configureCalypso(_config_next);
        }
    }

    function configureCalypso(stage) {
    	switch (stage) {
    	case 0:
            if (HighDataRate == false) {
                _DATA_RATE.requestWrite([0x01]b, { :writeType => Ble.WRITE_TYPE_WITH_RESPONSE });
            } else {
                _DATA_RATE.requestWrite([0x04]b, { :writeType => Ble.WRITE_TYPE_WITH_RESPONSE });
            }
    		break;
    		
    	case 1:
            if (_optional_sensors_enabled == false) {
                _PITCH_ENABLED.requestWrite([0x00]b, { :writeType => Ble.WRITE_TYPE_WITH_RESPONSE });
            } else {
                _PITCH_ENABLED.requestWrite([0x01]b, { :writeType => Ble.WRITE_TYPE_WITH_RESPONSE });
            }
    		break;
    		
    	default:
    		//Enable BLE notifications
    		_NOTIFICATION.getDescriptor(Ble.cccdUuid()).requestWrite([0x01,0x00]b);
    		_config_next = -1;
    		break;
    	}
        _config_next += 1;
    }

    function getSensorData() {
    	return _calypsoData;
    }

    function setDataRate(freq) {
        if (freq > 1) {HighDataRate = true;}
        else {HighDataRate = false;}
    }

    function enableOptSensors(b) {
        _optional_sensors_enabled = b;
    }

    function onScanStateChange(scanState, status) {
        _scanState = scanState;
        WatchUi.requestUpdate();
    }

    function isScanning() {
        return _scanState != Ble.SCAN_STATE_OFF;
    }
    
    function registerProfiles() {
		Ble.registerProfile(_CalypsoProfileDef);
	}
}