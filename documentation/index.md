# tizebraprint Module

## Description

TODO: Enter your module description here

## Accessing the tizebraprint Module

To access this module from JavaScript, you would do the following:

    var Zebra = require('io.eventhero.tizebraprint');

The Zebra variable is a reference to the Module object.

## Reference

### Zebra.findBluetoothPrinters

This method returns an array of Printer descriptions, including name and serial number. Printer object is ready to be passed to `Zebra.selectPrinter`.

### Zebra.findNetworkPrinters

This method returns an array of Printer descriptions, including name, IP address and port. Printer object is ready to be passed to `Zebra.selectPrinter`.

### Zebra.selectPrinter(<printer>)

Before printing, you must select a printer. Pass in either an IP and port or a bluetooth serial number.

### Zebra.print({...})

Method used to print to the selected printer.

#### Arguments

Takes one argument, a dictionary with the following keys:

* image[TiBlob]: An image blob to be printed. Either this field is required, or `pdf` is required.
* pdf[string]: Fully qualified path to a PDF file. Use `Ti.File.resolve()` to get said path. Either this field is required, or `image` is required.
* page[int] (optional): Page of the PDF file to print. If you pass "0", all pages will print. Default "0".
* callback[function] (optional): Callback function. Returns one object, with `success (boolean)` and `message (string)` properties.
* x[int] (optional): Horizontal starting position in dots. Default "0".
* y[int] (optional): Vertical starting position in dots.. Default "0".
* width[int] (optional): Desired width of the printed image. Passing -1 will preserve original width. Default "-1".
* height[int] (optional): Desired height of the printed image. Passing -1 will preserve original height. Default "-1".
* isInsideFormat[boolean] (optional): Boolean value indicating whether this image should be printed by itself (NO), or is part of a format being written to the connection (YES). Default "false".

## Usage

See TiZebraPrintExample in this repo.
