A Lua (>=5.3) script starting up both
[TuxGuitar](https://sourceforge.net/projects/tuxguitar/) and
[ZynAddSubFX](http://zynaddsubfx.sourceforge.net/index.html) and
connecting both via the JACK server (API>=v0.124.1) on GNU/Linux. So
there is no need to either alter the settings of one of the programs
or to do the wiring in QJackCtl manually.

# Requirements

### ZynAddSubFX

In order to use MIDI input port of **ZynAddSubFX** you, unfortunately,
have to compile it from source. 

So get a fresh
[copy](http://zynaddsubfx.sourceforge.net/download.html), unpack the
compressed file, and run the following commands

``` bash
cd zynaddsubfx*

# Create a separate folder to build the program
mkdir build
cd build

# Generate a customized environment to compile the source code in. If
# you got an error in here, you have to install the required
# (development) packages using your distributions' package manager.
cmake ..

# Build the program
make

# Try your new ZynAddSubFX version
./src/zynaddsubfx

# Install the package system-wide
sudo make install 
```

### TuxGuitar

Apart from the default package of TuxGuitar you also need its JACK
extension.

``` bash
sudo apt update
sudo apt install tuxguitar tuxguitar-jack
```

### Lua

Make sure you have both [Lua](https://www.lua.org/download.html) of at
least version **5.3** and
[LuaRocks](https://github.com/luarocks/luarocks/wiki/Download)
installed. 

In order to use the script in this repository you have to install the
[LuaJack](https://github.com/stetre/luajack) and the [luaposix](https://github.com/luaposix/luaposix) packages.

The first one you have to clone from Github yourself.

``` bash
git clone https://github.com/stetre/luajack
cd luajack
make
sudo make install
```
For the second one we use the Lua package manager.

``` bash
luarocks install --local luaposix
```

# Usage

First of all, make sure the **JACK server** is running on your
system. A convenient way of automating its start-up is to call [QjackCtl](https://qjackctl.sourceforge.io/).

To run the script just type the following lines in your terminal

``` bash
lua tux2zyn.lua
```

I would also recommend you to set the following alias in your
**.bashrc**.

``` bash
# Replace PATH-TO-TUX2LYN with the path to this repository.
alias tuxguitar='lua $HOME/PATH-TO-TUX2ZYN/tux2zyn.lua'
```
