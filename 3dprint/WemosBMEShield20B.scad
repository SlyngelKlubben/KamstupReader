BackPlateThickness=3;

WemosLOffset=8;
WemosWOffset=0.0; // -1.0 = displacement to ensure USB in center
WemosAntennaD=8;
WemosLength=34.2-WemosAntennaD/2+1; 
WemosWidth=25.6+1;
WemosThickness=4.0;
WemosShieldThickness=6.5;
WemosHoleD=2.5;
WemosHoleLOffset=2.0;
WemosHoleWOffset=3.5;
WemosHoleZOffset=1.5;

BMELength=13.5+1.2 ;
BMEWidth=10.6+0.4;
BMEThickness=4.5 ;
BMEHoleLOffset=2.75;//3.0;
BMEHoleWOffset=2.75;//3.0;

BMEMeassureLOffset=2.75+0.8/2;
BMEMeassureWOffset=BMEWidth-2.75-0.8/2;
BMEMeassureHoleD=2.0;
BMELOffset=-5;
BMEWOffset=0;
BMEZOffset=0;

CoverConnectHoleD=4;
CoverConnectHoleDepth=6;

CoverfactorL=1.15;
CoverfactorW=1.6;
CoverThickness=14.5;

TorusLOffset=45;
ConnectorPartD=10;

TorusD=35;
TorusThickness=TorusD/2-BMEMeassureHoleD/4;

ChargerLength=15;
ChargerWireD=2.5; // double wire
ChargerSingleWireD=4;

USBChargerThickness=6;
USBChargerWidth=12;
USBChargerWOffset=1;

JumperLength=9;
JumperWidth=6;
JumperDepth=10;


$fn=150;


//Front();

Back();


module Back(){
translate([(WemosLength+BMELength)/2,WemosWidth/2,-0.1-BackPlateThickness])
difference(){
BackPlateForBack();

translate([1,WemosWidth/2-2,BackPlateThickness-1])
cube([WemosLength-9, 3, BackPlateThickness], center = true);   

translate([1,-(WemosWidth/2-2),BackPlateThickness-1])
cube([WemosLength-9, 3, BackPlateThickness], center = true);


// Wemos reset
translate([-WemosLength/2+2.5,-(WemosWidth/2-4),BackPlateThickness-1])
cube([7, 6, BackPlateThickness], center = true);

// Wemos large IC    
translate([-4.5,6,BackPlateThickness-1])
cube([8,8, BackPlateThickness], center = true);

// Wemos Charger   
translate([-13,1,BackPlateThickness-2])
cube([8,9, BackPlateThickness], center = true);

// Wemos Smaller components   
translate([1,0,BackPlateThickness])
cube([21,18, BackPlateThickness], center = true);

// Part for fastning with screw
translate([15,0,-0.1])
cylinder(h=BackPlateThickness-1+0.2,r1=1.7,r2=4,center=false);

translate([10,0,-0.1])
cylinder(h=BackPlateThickness-1+0.2,r=3.5,center=false);

translate([15-2,0,0])
cube([5,2.5, 2.5], center = true);

// MicroUSB for power   
//translate([-20,1,BackPlateThickness-2])
//cube([8,11, BackPlateThickness], center = true);   

// DoubleWires for power   
translate([-20,0,BackPlateThickness-2])
cube([8,2*ChargerWireD, BackPlateThickness], center = true); 

// Single Wire for power   
//translate([-20,0,BackPlateThickness-2])
//cube([8,ChargerSingleWireD, BackPlateThickness], center = true); 

}    
}

module Front(){
difference(){
CoverCombined();
Innerparts();
}
}


module Innerparts(){
translate([0,WemosWidth/2,-BackPlateThickness])
//    ChargerUSB();
    Charger();
//     ChargerSingleWire();
    
translate([WemosLength/2+WemosLOffset,WemosWOffset+WemosWidth/2,WemosShieldThickness-0.15])
InnerHoleWemos();

translate([WemosLOffset,WemosWOffset,-0.1])
Wemos();

translate([WemosLength/2+WemosLOffset+BMELOffset,WemosWOffset+WemosWidth/2,WemosShieldThickness-BMEZOffset])
BME();

//Hole for BME shaped as middle of torus
translate([WemosLength/2+WemosLOffset+BMELOffset,WemosWOffset+WemosWidth/2,WemosShieldThickness-BMEZOffset+5])
rotate([0,-8,0])
    resize(newsize=[40,40,3])
CoverTorus();

translate([WemosLength/2+WemosLOffset+BMELOffset,WemosWOffset+WemosWidth/2,WemosShieldThickness-BMEZOffset+6])
rotate([0,-8,0])
    resize(newsize=[40,40,3])
CoverTorus();

translate([(WemosLength+BMELength)/2,WemosWidth/2,-0.1-BackPlateThickness])
BackPlate();
}

module BackPlate(){
    resize(newsize=[(WemosLength+BMELength)*CoverfactorL*0.9,WemosWidth*CoverfactorW*0.9,BackPlateThickness+0.2]) cylinder(h=2, r=10);
    }
    
module BackPlateForBack(){
    resize(newsize=[(WemosLength+BMELength)*CoverfactorL*0.9,WemosWidth*CoverfactorW*0.895,BackPlateThickness-1]) cylinder(h=2, r=10);
    }

module Wemos(){
cube([WemosLength, WemosWidth, WemosThickness], center = false);
    
// Wemos antenna part
  translate([WemosLength,WemosAntennaD/2,0])
  
  linear_extrude(height = WemosThickness, center = false, convexity = 10, twist = 0){
    hull() {
    translate([0,WemosWidth-WemosAntennaD,0]) circle(d=WemosAntennaD);
    circle(d=WemosAntennaD);
    }
  }
// Wemos non antenna part
translate([-1,0,0])
cube([WemosLength-2, WemosWidth, WemosShieldThickness], center = false);
}

module BME(){
// Hole for measuring
translate([0,0,0])
    cylinder(h = 20, d = BMEMeassureHoleD,center = false);

// Space for soldered wires on BME
translate([BMELength-BMELength/3-BMEMeassureLOffset,-BMEMeassureWOffset,BMEThickness-0.5])
rotate([0,45,0])
    cube([BMELength/3/sqrt(2), BMEWidth-0.5, BMELength/3/sqrt(2),], center = false);
}

module Cover(){
translate([0,0,0])
difference(){
resize(newsize=[(WemosLength+BMELength)*CoverfactorL,WemosWidth*CoverfactorW,CoverThickness*2]) sphere(r=10);
translate([0,0,50+BackPlateThickness])
cube([100,100,100], center = true);    
}
}

module InnerHoleWemos(){
// Hole under power in
translate([-WemosLength/2-3,-WemosWOffset,-3.0])
rotate([0,-50,0])
cube([14,5,7],center=true);

translate([-WemosLength/2+3.5,-WemosWOffset,1])    
cube([10,5,7],center=true);    

// Hole for jumper     
translate([WemosLength/2-3.1,-JumperWidth/2,-JumperDepth])
    cube([JumperLength, JumperWidth, JumperDepth], center = false);

// Space for pins
 translate([WemosLength/2-20/2-3,0,0])
cube([20,WemosWidth,CoverThickness-WemosShieldThickness-5],center=true);   

// small pyramide structure
translate([-2,-2.75,0])
resize(newsize=[(BMELength*1.5),BMEWidth*1.5,5])
rotate([0,0,45])
   cylinder(h = 10, r1 = 15, r2=10,$fn=4, center = false);   
}

module CoverTorus(){
difference(){
translate([0,0,0])
   cylinder(h = 10, r=10, center = false);  
    rotate_extrude(convexity = 10)
translate([TorusD/2-TorusThickness/2, 0, 0])
circle(r = TorusThickness/2, $fn = 50);
}
}

module CoverCombined(){    
translate([(WemosLength+BMELength)/2,WemosWidth/2,0])
rotate([0,180,0])
Cover();
}

module Charger(){
translate([-ChargerLength/4,-ChargerWireD/2,ChargerWireD/2])
     color("red")
rotate([90/4,0,0])
rotate([0,90,0])
 cylinder(h = ChargerLength, d = ChargerWireD/cos(30),$fn=8 ,center = false);

translate([-ChargerLength/4,ChargerWireD/2,ChargerWireD/2])
     color("red")
rotate([90/4,0,0])
rotate([0,90,0])
 cylinder(h = ChargerLength, d = ChargerWireD/cos(30),$fn=8 ,center = false);

translate([ChargerLength/4,0,0])
    cube([ChargerLength, ChargerWireD, ChargerWireD], center = true);
}

module ChargerSingleWire(){
translate([-ChargerLength/4,0,ChargerSingleWireD/2])
     color("red")
rotate([90/4,0,0])
rotate([0,90,0])
 cylinder(h = ChargerLength, d = ChargerSingleWireD/cos(30),$fn=8 ,center = false);

translate([ChargerLength/4,0,0])
    cube([ChargerLength, ChargerWireD, ChargerWireD], center = true);


}
module ChargerUSB(){
translate([0,USBChargerWOffset,USBChargerThickness/2-0.1])
    cube([ChargerLength,USBChargerWidth,USBChargerThickness], center = true);
}
