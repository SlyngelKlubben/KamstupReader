TangentSize=44;
TangentOuterR=150;
TangentSide=6.5;
TangentAngle=5;
TangentRDepth=1.5;
TangenWallThickness=1.5;
manifoldfix=0.01;
FiletTangentR=2;
SpringThickness=0.8;
SpringLength=16;
SpringWidth=5;
SpringAngle=15;
ButtonClickerDistance=25;
ButtonClickerR=3;
ButtonClickerHeight=0.6;

IkeaSize=33.7;
IkeaPCBThickness=1.2;
IkeaFiletR=5;
IkeaBatteryD=21;
IkeaBatteryThickness=3.8;
IkeaBatterySlotThickness=3.2;
IkeaBatteryLOffset=2.5;
IkeaBatteryWOffset=0.5;
IkeaButtonHoleD=3;
IkeaButtonLOffset=5.5;
IkeaButtonWOffset=0;

RotateConnectorDepth=2;
RotateConnectorRInner=1.5;
RotateConnectorThickness=0.5;
RotateConnectorCone=1.0;
ConnectorConeHeight=1.0;


BaseCutDown=2;
BaseCutInwards=4.5;
BaseSize=44.7;
BaseHeight=4.5;
BottomThickness=1.5;
BaseConnectWidth=5;
BaseConnectHeight=3;
BaseConnectThickness=1.5;
BaseConnectAngle=15;

translate([0,0,20])
SafetyTangent();
translate([0,0,8])
FugaClip();
Base();


module Base(){

// Base Connect click
translate([BaseSize/2,0,BaseConnectHeight])
rotate([0,BaseConnectAngle,0])
cube([BaseConnectThickness,BaseConnectWidth,BaseConnectHeight],center=true);

translate([-BaseSize/2,0,BaseConnectHeight])
rotate([0,-BaseConnectAngle,0])
cube([BaseConnectThickness,BaseConnectWidth,BaseConnectHeight],center=true);
    
    


translate([0,0,0])
difference(){
BaseModule();
translate([0,0,BaseHeight-IkeaPCBThickness+manifoldfix])
IkeaModule();
translate([0,0,0])
BaseCut();
//translate([0,0,BaseHeight-BaseCut+5])
//rotate([0,90,0])
//cylinder(h=TangentSize,r=RotateConnectorRInner,$fn=50,center=true);

// Hole for reset button
translate([-IkeaSize/2+IkeaButtonLOffset,IkeaButtonWOffset,BaseHeight-IkeaPCBThickness-2+2*manifoldfix])
cylinder(h=2,d=IkeaButtonHoleD*2,$fn=50,center=false);

translate([-IkeaSize/2+IkeaButtonLOffset,IkeaButtonWOffset,-manifoldfix-1])
cylinder(h=2*BaseHeight,d=IkeaButtonHoleD,$fn=50,center=true);

// Battery slot
translate([0,0,BaseHeight-IkeaPCBThickness+2*manifoldfix])
translate([IkeaBatteryLOffset,IkeaBatteryWOffset+100/2,+IkeaBatterySlotThickness/2-IkeaBatteryThickness])
cube([IkeaBatteryD,100,IkeaBatterySlotThickness],center=true);

// Battery slot
translate([0,+4.5,BaseHeight-IkeaPCBThickness+2*manifoldfix-3])
translate([IkeaBatteryLOffset,IkeaBatteryWOffset+100/2,+IkeaBatterySlotThickness/2-IkeaBatteryThickness])
cube([IkeaBatteryD,100,IkeaBatterySlotThickness],center=true);




// Rotate connector inner cone
translate([-TangentSize/2+3*(TangentSize-IkeaSize)/8+RotateConnectorCone,0,BaseHeight+ConnectorConeHeight+0.5])
rotate([0,-90,0])
cylinder(h=RotateConnectorCone,r1=RotateConnectorRInner/1.5,r2=0.1,$fn=50,center=true);

translate([TangentSize/2-3*(TangentSize-IkeaSize)/8-RotateConnectorCone,0,BaseHeight+ConnectorConeHeight+0.5])
rotate([0,90,0])
cylinder(h=RotateConnectorCone,r1=RotateConnectorRInner/1.5,r2=0.1,$fn=50,center=true);
}



}


module BaseCut(){

translate([0,BaseSize/2-BaseCutInwards/2+manifoldfix,BaseHeight-BaseCutDown/2+manifoldfix])
cube([BaseSize+manifoldfix,BaseCutInwards,BaseCutDown], center =true);

translate([0,-BaseSize/2+BaseCutInwards/2-manifoldfix,BaseHeight-BaseCutDown/2+manifoldfix])
cube([BaseSize+manifoldfix,BaseCutInwards,BaseCutDown], center =true);

translate([-BaseSize/2+BaseCutInwards/2-manifoldfix,0,BaseHeight-BaseCutDown/2+manifoldfix])
cube([BaseCutInwards,BaseSize+manifoldfix,BaseCutDown], center =true);
    
translate([BaseSize/2-BaseCutInwards/2+manifoldfix,0,BaseHeight-BaseCutDown/2+manifoldfix])
cube([BaseCutInwards,BaseSize+manifoldfix,BaseCutDown], center =true);
}
module BaseModule(){
    $fn=100;
translate([0,0,(BaseHeight-1)/2])  

minkowski() {
cube([BaseSize-2*FiletTangentR,BaseSize-2*FiletTangentR,BaseHeight-1], center=true);  
  cylinder(r=FiletTangentR,h=1);

}
translate([0,0,-BottomThickness+2*manifoldfix])  
cylinder(h=BottomThickness,r1=BaseSize/2-BottomThickness-3,r2=BaseSize/2-3, center=false);


// Rotate connector outer cone
translate([-TangentSize/2+3*(TangentSize-IkeaSize)/8,0,BaseHeight+ConnectorConeHeight])
rotate([0,-90,0])
{
cylinder(h=(TangentSize-IkeaSize)/4,r=RotateConnectorRInner+RotateConnectorThickness/2,$fn=50,center=true);
translate([0,0,(TangentSize-IkeaSize)/8+RotateConnectorCone/2])
cylinder(h=RotateConnectorCone,r1=RotateConnectorRInner,r2=0.1,$fn=50,center=true);
}
translate([TangentSize/2-3*(TangentSize-IkeaSize)/8,0,BaseHeight+ConnectorConeHeight])
rotate([0,90,0])
{
cylinder(h=(TangentSize-IkeaSize)/4,r=RotateConnectorRInner+RotateConnectorThickness/2,$fn=50,center=true);
translate([0,0,(TangentSize-IkeaSize)/8+RotateConnectorCone/2])
cylinder(h=RotateConnectorCone,r1=RotateConnectorRInner,r2=0.1,$fn=50,center=true);
}

// PCB click
translate([TangentSize/2-3.7*(TangentSize-IkeaSize)/8,0,BaseHeight+ConnectorConeHeight-0.4])
rotate([0,15,0])
cube([1,RotateConnectorRInner,RotateConnectorRInner],center=true);

translate([-TangentSize/2+3.7*(TangentSize-IkeaSize)/8,0,BaseHeight+ConnectorConeHeight-0.4])
rotate([0,-15,0])
cube([1,RotateConnectorRInner,RotateConnectorRInner],center=true);

// Rotate connector Stand
translate([-TangentSize/2+3*(TangentSize-IkeaSize)/8,0,BaseHeight/2+ConnectorConeHeight])
cube([(TangentSize-IkeaSize)/4,2*RotateConnectorRInner+RotateConnectorThickness,BaseHeight],center=true);

translate([TangentSize/2-3*(TangentSize-IkeaSize)/8,0,BaseHeight/2+ConnectorConeHeight])
cube([(TangentSize-IkeaSize)/4,2*RotateConnectorRInner+RotateConnectorThickness,BaseHeight],center=true);



}
module IkeaModule(){
    $fn=100;
translate([0,0,(IkeaPCBThickness-1)/2])  

minkowski() {
cube([IkeaSize-2*IkeaFiletR,IkeaSize-2*IkeaFiletR,IkeaPCBThickness-1], center=true);  
  cylinder(r=IkeaFiletR,h=1);
}

// Lowerings for PCB soldering
//translate([0,0,(IkeaPCBThickness-1)/2])  

minkowski() {
cube([IkeaSize-2*IkeaFiletR-6,IkeaSize-2*IkeaFiletR-6,IkeaPCBThickness], center=true);  
  cylinder(r=IkeaFiletR,h=1);
}
// Hole for Battery
translate([IkeaBatteryLOffset,IkeaBatteryWOffset,-IkeaBatteryThickness+manifoldfix])
  cylinder(h=IkeaBatteryThickness,d=IkeaBatteryD, center=false);

}


module Tangent(){
// Rotate connector
translate([-TangentSize/2+(TangentSize-IkeaSize)/8,0,RotateConnectorDepth])
rotate([0,90,0])
difference(){
cylinder(h=(TangentSize-IkeaSize)/4,r=RotateConnectorRInner+RotateConnectorThickness,$fn=50,center=true);
translate([0,0,(TangentSize-IkeaSize)/8-RotateConnectorRInner/2])
cylinder(h=RotateConnectorRInner+manifoldfix,r1=0.1,r2=RotateConnectorRInner,$fn=50,center=true);
}

translate([TangentSize/2-(TangentSize-IkeaSize)/8,0,RotateConnectorDepth])
rotate([0,90,0])
difference(){
cylinder(h=(TangentSize-IkeaSize)/4,r=RotateConnectorRInner+RotateConnectorThickness,$fn=50,center=true);
translate([0,0,-(TangentSize-IkeaSize)/8+RotateConnectorRInner/2])
cylinder(h=RotateConnectorRInner+manifoldfix,r1=RotateConnectorRInner,r2=0.1,$fn=50,center=true);

}



// button clickers
translate([0,ButtonClickerDistance/2,TangentSide-TangentRDepth-TangenWallThickness-ButtonClickerHeight])
rotate([0,0,45])
cylinder(h=ButtonClickerHeight,r1=ButtonClickerR, r2=ButtonClickerR+ButtonClickerHeight,$fn=4,center=false);

translate([0,-ButtonClickerDistance/2,TangentSide-TangentRDepth-TangenWallThickness-ButtonClickerHeight])
rotate([0,0,45])
cylinder(h=ButtonClickerHeight,r1=ButtonClickerR, r2=ButtonClickerR+ButtonClickerHeight,$fn=4,center=false);


// Springs
translate([14,0,TangentSide-TangentRDepth-TangenWallThickness+SpringThickness/2])
TangentSprings();
translate([-14,0,TangentSide-TangentRDepth-TangenWallThickness+SpringThickness/2])
TangentSprings();

difference(){
translate([0,0,TangentSide/2])
cube([TangentSize,TangentSize,TangentSide], center=true);

translate([0,0,TangentOuterR+TangentSide-TangentRDepth])
rotate([0,90,0])
cylinder(TangentSize*2,r=TangentOuterR,$fn=1000,center=true);

translate([0,0,-manifoldfix])
rotate([0,0,45])
cylinder(h=(TangentSide-TangentRDepth-TangenWallThickness), r1=sqrt(2)*(TangentSize-2*TangenWallThickness)/2,r2=sqrt(2)*((TangentSize-2*TangenWallThickness)/2-(TangentSide-TangentRDepth-TangenWallThickness)),$fn=4, center=false);



// Angled sides of tagent
translate([0,-TangentSize/2-10/2,0])
rotate([-TangentAngle,0,0])
cube([TangentSize+manifoldfix,10,TangentSide*3], center =true);
    
translate([0,+TangentSize/2+10/2,0])
rotate([TangentAngle,0,0])
cube([TangentSize+manifoldfix,10,TangentSide*3], center =true);
// Filet of corners
TangentCornerFilet();


// hole for rotate connect
translate([-TangentSize/2+(TangentSize-IkeaSize)/4,0,RotateConnectorDepth])
rotate([0,90,0])cylinder(h=(TangentSize-IkeaSize)/2+manifoldfix,r=RotateConnectorRInner+RotateConnectorThickness,$fn=50,center=true);

translate([TangentSize/2-(TangentSize-IkeaSize)/4-1/2,0,RotateConnectorDepth])
rotate([0,90,0])cylinder(h=(TangentSize-IkeaSize)/2+manifoldfix-1,r=RotateConnectorRInner+RotateConnectorThickness,$fn=50,center=true);
}
}
module SafetyTangent(){
translate([0,0,4])
difference(){
    Tangent();
    // Cylinder protect of Base Click
    translate([TangentSize/2,0,-3.5])
    rotate([0,90,0])cylinder(h=2,r=5.5,$fn=50,center=true);

    translate([-TangentSize/2,0,-3.5])
    rotate([0,90,0])cylinder(h=2,r=5.5,$fn=50,center=true);
}
}

module TangentSprings(){
rotate([SpringAngle,0,0])
translate([0,-SpringLength/2,0])
cube([SpringWidth,SpringLength,SpringThickness], center=true);
rotate([-SpringAngle,0,0])
translate([0,SpringLength/2,0])
cube([SpringWidth,SpringLength,SpringThickness], center=true);
}
// Corner filet 
module TangentCornerFilet(){
difference(){
TangentCornerFiletPrep();
translate([-TangentSize/2+FiletTangentR,-TangentSize/2+FiletTangentR,0])
rotate([-TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,$fn=50,center=true);
translate([TangentSize/2-FiletTangentR,-TangentSize/2+FiletTangentR,0])
rotate([-TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,$fn=50,center=true);
translate([-TangentSize/2+FiletTangentR,TangentSize/2-FiletTangentR,0])
rotate([TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,$fn=50,center=true);
translate([TangentSize/2-FiletTangentR,TangentSize/2-FiletTangentR,0])
rotate([TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,$fn=50,center=true);
}
}

module TangentCornerFiletPrep(){
    translate([-TangentSize/2,-TangentSize/2,0])
rotate([-TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,$fn=50,center=true);
translate([TangentSize/2,-TangentSize/2,0])
rotate([-TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,$fn=50,center=true);
translate([-TangentSize/2,TangentSize/2,0])
rotate([TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,$fn=50,center=true);
translate([TangentSize/2,TangentSize/2,0])
rotate([TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,$fn=50,center=true);
}

module FugaClip(){
    difference(){
        translate([0,0,6.9])
        cube([31,40,1.3],center=true);
        translate([7,0,6.9])
        cube([7,7,2],center=true);
        translate([-7,0,6.9])
        cube([7,7,2],center=true);
        translate([0,0,6.9])
        cube([4,4,2],center=true);
    }
    
    // Rotate connector
    translate([15.3,0,6])
    rotate([0,90,0])
    difference(){
        cylinder(h=(TangentSize-IkeaSize)/4,r=RotateConnectorRInner/1.5+RotateConnectorThickness,$fn=50,center=true);
        translate([0,0,(TangentSize-IkeaSize)/8-RotateConnectorRInner/2])
        cylinder(h=RotateConnectorRInner+manifoldfix,r1=0.1,r2=RotateConnectorRInner/1.5,$fn=50,center=true);
    }
    translate([-15.3,0,6])
    rotate([0,-90,0])
    difference(){
        cylinder(h=(TangentSize-IkeaSize)/4,r=RotateConnectorRInner/1.5+RotateConnectorThickness,$fn=50,center=true);
        translate([0,0,(TangentSize-IkeaSize)/8-RotateConnectorRInner/2])
        cylinder(h=RotateConnectorRInner+manifoldfix,r1=0.1,r2=RotateConnectorRInner/1.5,$fn=50,center=true);
    }
    
    // button clickers
    translate([0,ButtonClickerDistance/2,TangentSide-TangentRDepth-TangenWallThickness-ButtonClickerHeight+2.5])
    rotate([0,0,45])
    cylinder(h=ButtonClickerHeight+1,r1=ButtonClickerR, r2=ButtonClickerR+ButtonClickerHeight,$fn=4,center=false);

    translate([0,-ButtonClickerDistance/2,TangentSide-TangentRDepth-TangenWallThickness-ButtonClickerHeight+2.5])
    rotate([0,0,45])
    cylinder(h=ButtonClickerHeight+1,r1=ButtonClickerR, r2=ButtonClickerR+ButtonClickerHeight,$fn=4,center=false);
}
