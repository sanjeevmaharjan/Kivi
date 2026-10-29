 # Replication on Arch Linux

## Install system packages

```bash
sudo pacman -Syu
sudo pacman -S --needed git bc tk gnuplot python base-devel # or spin
```

`base-devel` supplies the tools required to build Spin. You could also install spin instead of building.

## Clone Kivi and set up Python = 3.8

```bash
git clone https://github.com/sanjeevmaharjan/Kivi.git
cd Kivi
python --version
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -c 'import tkinter'
```

The project requires a Python version == 3.8,
install that version with `pyenv` and ensure `tk` is installed before building
Python. Optionally, create the virtual environment using the selected interpreter.

## Build Spin (Or install using pacman)

```bash
# ./install.sh does it for you too
mkdir -p libs results temp

# pacman -S spin # already done above

# OR

git clone https://github.com/nimble-code/Spin.git libs/Spin
make -C libs/Spin/Src
```

## Run Kivi

Run the runner from `bin` with the virtual environment active (Examples in the README.md):

```bash
cd bin
python3 kivi_runner.py -p ../examples/c3/configs
python3 kivi_runner.py -p ../examples/c3/logs -log
python3 kivi_runner.py -p ../examples/c3/logs -log -si
```

## Run evaluation and plot results

```bash
cd eval
./bash_eval_linux.sh 2 2
gnuplot plot.plt
```

Run the evaluation from `bin/eval`; it may take time and create or replace
result files. Check the script's usage/source before changing its arguments.
