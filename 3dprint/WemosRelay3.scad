EndThickness=1.5;

RelayHeight=15;
RelayWidth=16+1;
RelayWidthOffset=-1;
RelayLenghtOffset=10;

BoxThickness=2;

PCBSpace=5.0;
SlideWidth=3.0;

PCBLength=34.2+1;
PCBWidth=25.6+1;
PCBThickness=4.0;
Manifoldfix=0.01;

ScrewHoleD=4;
ScrewHoleLengthOffset=4.5;
ScrewHoleDistance=5;
ConnectorHeight=10;
$fn=100;

Space=0.1;

OuterBoxThickness=1;

//Outer();


difference(){
Inner();
OuterForInner();
    
}

module OuterForInner(){
difference(){
translate([-Space,-PCBWidth/2-BoxThickness-Space,-Space])
cube([PCBLength+BoxThickness-RelayLenghtOffset,PCBWidth+2*BoxThickness+2*Space,RelayHeight+PCBSpace+2*PCBThickness+2*BoxThickness+2*Space], center=false);

translate([BoxThickness,-PCBWidth/2-BoxThickness+OuterBoxThickness+Space,OuterBoxThickness+Space])
cube([PCBLength+BoxThickness-RelayLenghtOffset,PCBWidth+2*BoxThickness-2*OuterBoxThickness-2*Space,RelayHeight+PCBSpace+2*PCBThickness+2*BoxThickness-2*OuterBoxThickness-2*Space], center=false);
}
}
module Outer(){
difference(){
translate([0,-PCBWidth/2-BoxThickness,0])
cube([PCBLength+BoxThickness-RelayLenghtOffset,PCBWidth+2*BoxThickness,RelayHeight+PCBSpace+2*PCBThickness+2*BoxThickness], center=false);

translate([BoxThickness,-PCBWidth/2-BoxThickness+OuterBoxThickness,OuterBoxThickness])
cube([PCBLength+BoxThickness-RelayLenghtOffset,PCBWidth+2*BoxThickness-2*OuterBoxThickness,RelayHeight+PCBSpace+2*PCBThickness+2*BoxThickness-2*OuterBoxThickness], center=false);
}
}



module Inner(){
difference(){
//Inner box
translate([0,-PCBWidth/2-BoxThickness,0])
cube([PCBLength+BoxThickness,PCBWidth+2*BoxThickness,RelayHeight+PCBSpace+2*PCBThickness+2*BoxThickness], center=false);

//PCB Relay
translate([-Manifoldfix,-PCBWidth/2,PCBSpace+PCBThickness+BoxThickness])
cube([PCBLength,PCBWidth,PCBThickness-1], center=false);

//PCB Wemos
translate([-Manifoldfix,-PCBWidth/2,BoxThickness])
cube([PCBLength,PCBWidth,PCBThickness+1], center=false);

//PCB Space
translate([-Manifoldfix,SlideWidth-PCBWidth/2,BoxThickness+PCBThickness-Manifoldfix])
cube([PCBLength,PCBWidth-2*SlideWidth,PCBSpace+2*Manifoldfix], center=false);

//PCB relay
translate([-Manifoldfix,RelayWidthOffset-RelayWidth/2,BoxThickness])
cube([PCBLength-RelayLenghtOffset,RelayWidth,RelayHeight+PCBSpace+2*PCBThickness], center=false);

//Relay connectors
translate([-Manifoldfix,RelayWidthOffset-RelayWidth/2,BoxThickness])
cube([PCBLength,RelayWidth,ConnectorHeight+PCBSpace+2*PCBThickness], center=false);


//ScrewHoles;
translate([PCBLength-ScrewHoleLengthOffset,RelayWidthOffset,RelayHeight+PCBSpace+2*PCBThickness+2*BoxThickness]){
cylinder(h=3*RelayHeight,d=ScrewHoleD,center=true);
translate([0,-ScrewHoleDistance,0])
cylinder(h=3*RelayHeight,d=ScrewHoleD,center=true);
translate([0,+ScrewHoleDistance,0])
cylinder(h=3*RelayHeight,d=ScrewHoleD,center=true);
}

//Connector Holes;
translate([PCBLength-ScrewHoleLengthOffset,RelayWidthOffset,PCBSpace+2*PCBThickness+2*BoxThickness])
rotate([0,90,0])
{
cylinder(h=3*RelayHeight,d=ScrewHoleD,center=true);
translate([0,-ScrewHoleDistance,0])
cylinder(h=3*RelayHeight,d=ScrewHoleD,center=true);
translate([0,+ScrewHoleDistance,0])
cylinder(h=3*RelayHeight,d=ScrewHoleD,center=true);
}
}
}