require("settings");
dofile("wifi.lua")
LEDPIN=4;
enfant='victor';
gpio.mode(4,gpio.OUTPUT);
gpio.write(4,gpio.HIGH);
blinkactif=0;
function  battery_level(i)
	local level=math.floor(i /0.05);
	if  (level>100 or level<0) then return 255; else return level; end
end
function NodeSleep()
	node.restart();
end
function get_parental_filter()
	url="http://192.168.2.8/domoticz_scripts/freebox/freebox_parental.php";
	http.get(url, nil, function(code, data)
		    if (code ==200) then
		       t = sjson.decode(data)
		       print (enfant.." state:"..t[enfant]['state'].." nextchange:"..t[enfant]['nextchange']);
		        if ((t[enfant]['state']=='allowed' and t[enfant]['nextchange']<=30) ) then  
		      		print("case1");
		      		blink(500 - 10 * (30 -  t[enfant]['nextchange'] )); blinkactif=1; 
		      	elseif ( t[enfant]['state']=='denied' ) then 
		      		print("case2");
		      		blink(100);blinkactif=1; 
		      	else
		      		print("case3");
		      		blinkstop() ; 
		      	end
		    else
		      print("HTTP request failed");
		      --node.restart()
		    end
		    get_switch()
	end)
end

function get_switch()
	url="http://"..DOMO_IP..":"..DOMO_PORT.."/json.htm?type=devices&rid=157";
	http.get(url, nil, function(code, data)
		    if (code ==200) then
		      t = sjson.decode(data)
		      print ("alerte="..t['result'][1]['Data']);
		      if (t['result'][1]['Data']=='On') then  blink(200); elseif blinkactif==1 then print ("") else blinkstop() ; end
		    else
		      print("HTTP request failed");
		     -- node.restart()
		    end

	  	end)
end
function main()
	get_parental_filter();
	tmr.alarm(0, DELAIPOST*1000, 1, function()
		gpio.write(4,gpio.LOW);
		tmr.delay(100);
		gpio.write(4,gpio.HIGH);
		get_parental_filter()
	end)
end
function blink(duree)
	i=1;
	print ("blink")
	blinktimer:register(duree/2, tmr.ALARM_AUTO, function()	i=i+1; gpio.write(LEDPIN,i%2); 	end)
	blinktimer:start()
end

function blinkstop()
	print ("stop blink")
	gpio.write(4,gpio.HIGH);
 	blinktimer:stop() 
end
blinktimer = tmr.create();
ConnectWifi(main,NodeSleep);

