TangentSize=44.8;
TangentOuterR=150;
TangentSide=8;
TangentAngle=0;
TangentRDepth=1.5;
TangenWallThickness=1.0;
manifoldfix=0.01;
FiletTangentR=2;
MagnetCylinderR=2.5;
MagnetCylinderHolderHeight=3;
MagnetCylinderDepth=3;
MagnetCylinderThickness=0.6;
MagnetCylinderOffset=2.0;
ScrewDistance=37.8;
MagnetHolderOffset=-0.7;
LockHoleOffset = (TangentSize/2-18);
LockHoleLength= 8;
LockHoleD=4;
$fn=100;




Tangent();

module Tangent(){

difference(){
translate([-ScrewDistance/2,0,TangentSide-MagnetCylinderHolderHeight])
cylinder(h=MagnetCylinderHolderHeight, r=MagnetCylinderR+MagnetCylinderThickness, center=false);
    
translate([-ScrewDistance/2,0,-manifoldfix+TangentSide-MagnetCylinderDepth])
cylinder(h=MagnetCylinderHolderHeight, r=MagnetCylinderR, center=false);

translate([-ScrewDistance/2+2.4,-TangentSide/2,-manifoldfix])
cube([TangentSide,TangentSide,TangentSide], center=false);

}
difference(){
translate([ScrewDistance/2,0,TangentSide-MagnetCylinderHolderHeight])
cylinder(h=MagnetCylinderHolderHeight, r=MagnetCylinderR+MagnetCylinderThickness, center=false);
    
translate([ScrewDistance/2,0,-manifoldfix+TangentSide-MagnetCylinderDepth])
cylinder(h=MagnetCylinderHolderHeight, r=MagnetCylinderR, center=false);

translate([ScrewDistance/2-TangentSide-2.4,-TangentSide/2,-manifoldfix])
cube([TangentSide,TangentSide,TangentSide], center=false);

}





difference(){
translate([0,0,TangentSide/2])
cube([TangentSize,TangentSize,TangentSide], center=true);


translate([0,0,-manifoldfix])
rotate([0,0,45])
cylinder(h=(TangentSide-TangenWallThickness), r=sqrt(2)*(TangentSize-2*TangenWallThickness)/2,$fn=4, center=false);


    
    
// Cylinder center
translate([0,0,-29])
  rotate([0,90,0])
cylinder(h=TangentSize*2, r=34, center=true);  
    

// Angled sides of tagent
translate([0,-TangentSize/2-10/2,0])
rotate([-TangentAngle,0,0])
cube([TangentSize+manifoldfix,10,TangentSide*3], center =true);
    
translate([0,+TangentSize/2+10/2,0])
rotate([TangentAngle,0,0])
cube([TangentSize+manifoldfix,10,TangentSide*3], center =true);
// Filet of corners
TangentCornerFilet();

}



}


// Corner filet 
module TangentCornerFilet(){
difference(){
TangentCornerFiletPrep();
translate([-TangentSize/2+FiletTangentR,-TangentSize/2+FiletTangentR,0])
rotate([-TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,center=true);
translate([TangentSize/2-FiletTangentR,-TangentSize/2+FiletTangentR,0])
rotate([-TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,center=true);
translate([-TangentSize/2+FiletTangentR,TangentSize/2-FiletTangentR,0])
rotate([TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,center=true);
translate([TangentSize/2-FiletTangentR,TangentSize/2-FiletTangentR,0])
rotate([TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,center=true);
}
}

module TangentCornerFiletPrep(){
    translate([-TangentSize/2,-TangentSize/2,0])
rotate([-TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,center=true);
translate([TangentSize/2,-TangentSize/2,0])
rotate([-TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,center=true);
translate([-TangentSize/2,TangentSize/2,0])
rotate([TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,center=true);
translate([TangentSize/2,TangentSize/2,0])
rotate([TangentAngle,0,0])
cylinder(h=TangentSide*3,r=FiletTangentR,center=true);
}