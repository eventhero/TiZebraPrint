var Zebra = require('io.eventhero.tizebraprint');

var win = Ti.UI.createWindow({
	backgroundColor:'#fff',
	title:'Printers',
});

var navWin = Ti.UI.iOS.createNavigationWindow({
	window:win,
});

var printerTable = Ti.UI.createTableView();
win.add(printerTable);

navWin.open();

var findPrinters = function(){
	printerTable.data = [];
	var rows = [{title:'Search Again'}];

	var bluetoothPrinters = Zebra.findBluetoothPrinters();
	for (var i in bluetoothPrinters) {
		rows.push({
			printer:bluetoothPrinters[i],
			title:bluetoothPrinters[i].name,
		});
	}
	
	var networkPrinters = Zebra.findNetworkPrinters();
	for (var i in networkPrinters) {
		rows.push({
			printer:networkPrinters[i],
			title:networkPrinters[i].name,
		});
	}

	printerTable.data = rows;
}

printerTable.addEventListener('click',function(e){
	if (!e.row.printer) {
		findPrinters();
	} else {
		Zebra.selectPrinter(e.row.printer); // the get printer calls return an object compatable with this method to choose the printer.
		var d = Ti.UI.createOptionDialog({
			title:'Choose option to print:',
			options:['Image','PDF 1 Page','PDF All Pages','Cancel'],
		});
		d.addEventListener('click',function(e){
			if (e.index === 0) {
				// print image
				var imageFile = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory,'test.png');
				var imageBlob = imageFile.read();
				Zebra.print({
					image:imageBlob,
					callback:function(e){
						if (e.success) {
							alert('Printed!');
						} else {
							Ti.API.error(JSON.stringify(e));
							alert(e.message);
						}
					}
				});
			} else if (e.index === 1) {
				// print first page
				var pdfFile = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory,'test.pdf');
				var pdfBlob = pdfFile.read();
				Zebra.print({
					pdf:pdfBlob,
					page:1,
					callback:function(e){
						if (e.success) {
							alert('Printed!');
						} else {
							Ti.API.error(JSON.stringify(e));
							alert(e.message);
						}
					}
				});
			} else if (e.index === 2) {
				// print all pages
				var pdfFile = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory,'test.pdf');
				var pdfURL = pdfFile.resolve();
				Zebra.print({
					pdf:pdfURL,
					callback:function(e){
						if (e.success) {
							alert('Printed!');
						} else {
							Ti.API.error(JSON.stringify(e));
							alert(e.message);
						}
					}
				});
			}
		});
		d.show();
	}
});

findPrinters();