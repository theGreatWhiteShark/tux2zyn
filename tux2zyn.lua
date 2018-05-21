--- tuxguitar.lua - Using Zynaddsubfx to intonate TuxGuitar songs and
---  LuaJack to combine the two.

jack = require( 'luajack' )
posix = require( 'posix' )

-- Open a JACK client - Dummy, we won't use this one
jack_client, jack_error_message =
   pcall( jack.client_open, "tux2zyn", { no_start_server = true } )

-- Check whether the server was actually running.
if not jack_client and string.find( jack_error_message,
				    "server_failed" ) then
   error( "The JACK server is not running! Please start it beforehand"
	)
end

-- Find the local configuration files of ZynAddSubFX
index_zynaddsubfx = 0
-- Search all files in the home folder for one containing both
-- "zynaddsubfx" and the suffix ".xmz" in its name. Maybe this is not
-- the default way of ZynAddSubFX to save its configuration but the
-- manual does not give any clues how and where it is stored instead.
for ii, ff in ipairs( posix.dir( posix.getenv()[ "HOME" ] ) ) do
   if string.find( ff, "zynaddsubfx" ) then
      if string.find( ff, ".xmz" ) then
	 zynaddsubfx_conf_file = ff
	 index_zynaddsubfx = 1
      end
   end
end


-- Start up ZynAddSubFX
-- Check whether the application is installed
if os.execute( 'which zynaddsubfx' ) then
   -- When no configuration files are found the script will fall back
   -- to the configuration file provided within the repositoy.
   if index_zynaddsubfx == 0 then
      os.execute( 'zynaddsubfx -I jack -l res/conf_zynaddsubfx.xmz &' )
   else
      os.execute( 'zynaddsubfx -I jack -l ' ..
		  posix.getenv()[ "HOME" ] .. "/" ..
		  zynaddsubfx_conf_file .. ' &' )
   end
else
   error( "Could not find 'zynaddsubfx'!" )
end

-- Give the program two second to start up
posix.sleep( 2 )

-- Check the configuration of TuxGuitar
if os.execute( 'which tuxguitar' ) then
   -- Find the folder the configuration of TuxGuitar is saved in.
   for ii, dd in ipairs( posix.dir( posix.getenv()[ "HOME" ] ) ) do
      if string.find( dd, "tuxguitar" ) then
	 tuxguitar_folder = dd
	 break
      end
   end

   -- Check whether the configuration file exists (this should be
   -- always the case).
   tuxguitar_conf_existence = nil
   for ii, dd in ipairs( posix.dir( posix.getenv()[ "HOME" ] ..
				    "/" .. tuxguitar_folder ) ) do
      if string.find( dd, "config.properties" ) then
	 tuxguitar_conf_existence = true
      end
   end
   if tuxguitar_conf_existence then
   else
      error( "Could not locate the TuxGuitar configuration file!" )
   end
   
   -- Load the content of the configuration file and make a copy in
   -- case we mess something up
   tuxguitar_conf_file =
      io.open( posix.getenv()[ "HOME" ] .. "/" ..
	       tuxguitar_folder .. "/" .. "config.properties", "r" )
   io.input( tuxguitar_conf_file )
   tuxguitar_conf_content = tuxguitar_conf_file:read( "*all" )
   tuxguitar_conf_file_backup =
      io.open( posix.getenv()[ "HOME" ] .. "/" ..
	       tuxguitar_folder .. "/" ..
	       "old.config.properties.tux2zyn", "w+" )
   io.output( tuxguitar_conf_file_backup )
   tuxguitar_conf_file_backup:write( tuxguitar_conf_content )
   tuxguitar_conf_file_backup:close()
   
   -- Set the MIDI port to JACK and the MIDI sequencer to
   -- tuxguitar-jack
   -- Lua's capability of string handling are fairly
   -- limited. Therefore I will only comment the corresponding lines
   -- and a the corrected ones.
   if string.find( tuxguitar_conf_content,
		   "midi.port=tuxguitar-jack" ) then
   else
      -- Overwrite the current configuration of the MIDI port
      if string.find( tuxguitar_conf_content, "midi.port" ) then
	 tuxguitar_conf_content = string.gsub(
	    tuxguitar_conf_content, "midi.port", "#midi.port" )
      end
      tuxguitar_conf_content =
	 tuxguitar_conf_content .. "midi.port=tuxguitar-jack\n"
   end
   if string.find( tuxguitar_conf_content,
		   "midi.sequencer=tuxguitar-jack" ) then
   else
      --Overwrite the ccurrent configuration of the MIDI sequencer
      if string.find( tuxguitar_conf_content, "midi.sequencer" ) then
	 tuxguitar_conf_content = string.gsub(
	    tuxguitar_conf_content, "midi.sequencer",
	    "#midi.sequencer" )
      end
      tuxguitar_conf_content =
	 tuxguitar_conf_content .. "midi.sequencer=tuxguitar-jack\n"
   end
   
   -- Write the modified configuration to file
   tuxguitar_conf_file =
      io.open( posix.getenv()[ "HOME" ] .. "/" ..
	       tuxguitar_folder .. "/" .. "config.properties", "w+" )
   io.output( tuxguitar_conf_file )
   tuxguitar_conf_file:write( tuxguitar_conf_content )
   tuxguitar_conf_file:close()
else
   error( "Could not find 'tuxguitar'!" )
end

-- Start up TuxGuitar and suppress it tons of error messages
os.execute( 'tuxguitar > /dev/null 2>/dev/null &' )

-- TuxGuitar needs some more time to start up
posix.sleep( 6 )

-- Get the names of all available ports and extract those belonging to
-- Tuxguitar and ZynAddSubFX.
jack_ports_all = jack.get_ports( jack_client )

-- Find all ports containing the string "TuxGuitar"
index_tuxguitar = 0
ports_tuxguitar = {}
for ii, pp in ipairs( jack_ports_all ) do
   if ( string.find( pp, "TuxGuitar" ) ) then
      index_tuxguitar = index_tuxguitar + 1
      ports_tuxguitar[ index_tuxguitar ] = pp
   end
end

-- Usually there should be only one output port of TuxGuitar (a MIDI
-- one)
if index_tuxguitar == 1 then
   if string.find( ports_tuxguitar[ 1 ], "[O|o]utput" ) then
      port_tuxguitar_output = ports_tuxguitar[ 1 ]
   else
      error( "The JACK port of TuxGuitar does not seem to be an output port" )
   end
else
   -- Find the first output port and use it.
   port_tuxguitar_output = nil
   for ii, pp in ipairs( ports_tuxguitar ) do
      if string.find( pp, "[O|o]utput" ) then
	 port_tuxguitar_output = pp
	 break
      end
   end
   -- Check whether the above assignment worked
   if port_tuxguitar_output then
   else
      error( "No JACK output port of TuxGuitar found!" )
   end
end


-- Find all ports containing the string "zynaddsubfx"
index_zynaddsubfx = 0
ports_zynaddsubfx = {}
for ii, pp in ipairs( jack_ports_all ) do
   if ( string.find( pp, "zynaddsubfx" ) ) then
      index_zynaddsubfx = index_zynaddsubfx + 1
      ports_zynaddsubfx[ index_zynaddsubfx ] = pp
   end
end

-- Find the MIDI input port and use line outs.
port_zynaddsubfx_input = nil
for ii, pp in ipairs( ports_zynaddsubfx ) do
   if string.find( pp, "midi_input" ) then
      port_zynaddsubfx_input = pp
   elseif string.find( pp, "out_1" ) then
      port_zynaddsubfx_output_1 = pp
   elseif string.find( pp, "out_2" ) then
      port_zynaddsubfx_output_2 = pp
   end
end
-- Check whether the above assignment worked
if port_zynaddsubfx_input then
else
   error( "No JACK MIDI input port of ZynAddSubFX found!" )
end

-- Connect the MIDI ports of both ZynAddSubFX and TuxGuitar
jack.nport_connect( jack_client,
		    port_tuxguitar_output,
		    port_zynaddsubfx_input )

-- Connect the lineout of ZynAddSubFX to the system playback
jack.nport_connect( jack_client, "system:playback_1",
		    port_zynaddsubfx_output_1 )
jack.nport_connect( jack_client, "system:playback_2",
		    port_zynaddsubfx_output_2 )
