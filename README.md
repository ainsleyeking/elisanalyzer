# ELISA Data Analyzer

This package will allow you to easily analyse ELISA data from a Cytation5 plate reader. Below describes how to use it.

**1. Load your data.** The data needs to be in the format of a .csv file, and the file from the Cytation is probably an Excel spreadsheet, so just export the data into a .csv file. Save this into the "data" folder inside this package.

**2. Create a key.** The program needs to know what strain you have put in each well, where the standards are, etc. To do this, you need to create a key.

  a. Make a copy of the key template ("key_template.csv"), which can be found in the "keys" folder, and open it up. The row and column numbers of the 96-well plate should be in the first two columns. Leave these alone.

  b. Note what "type" of data is in each well. You have 5 options:

  -   "sample": A sample you collected and want analyzed

  -   "mac": The macrophage-only control

  -   "rd": The reagent dilutent control

  -   "standard": One of the standards

  -   "NA": Empty wells

  c. In the "standard_conc" column, IN ONLY THE ROWS CONTAINING THE STANDARDS (#4 above), note what concentration of standard was used. Mark all other rows as "NA".

  d. In the "strain" column, IN ONLY THE ROWS CONTAINING SAMPLES (#1 above), indicate what strain was used in each well. Mark all other rows, and any empty wells, as "NA".

  e. Make sure you save your key in the "keys" folder.

**3. Run the program.** In the "R" folder, open up "elisanalyzer.R". You now need to tell it which files to analyze.

  a. At the top of the document, below the packages to install, there is a space to "Read the .csv file containing the data". Inside the parentheses and quotation marks, indicate the file path to your data. This should be "data/filename.csv".

  -   For example, it could read:

```         
elisa <- read_csv("data/elisadata.csv")
```

  b. Directly below that, there is a space to "Add the key". Do the same thing here, indicting the file path to your key. This should be "keys/filename.csv"

  -   For example, it could read:

```         
key <- read_csv("keys/mykey.csv")
```

  c. Run the program by holding the command button and hitting Return repeatedly, starting from the very top of the code, until you get to the first "STOP HERE #1". You should be looking at your standard curve. Make sure your standards fit well with the curve.

  d. Keep running the program the same way until you get to "STOP HERE #2". The last line you run should open a new tab in RStudio with the final, analyzed data in a table. You may copy this into a GraphPad Prism file if you wish.

  e. Run the rest of the program. This should generate a bar graph with your data.
