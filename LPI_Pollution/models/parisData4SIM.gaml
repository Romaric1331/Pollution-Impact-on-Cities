/**
* Name: parisData4SIM
* Based on the internal skeleton template. 
* Author: JB07E36L
* Tags: 
*/

model parisData4SIM

global {
	/** Insert the global definitions, variables and actions here */
	
	
	//file road_shape_file<-file("../includes/geofabrik_roads_projected_rgf93cc49zone8_clipped.shp");
	file road_shape_file<-file("../includes/Paris BIG/geofabrik_roads_projected_rgf93cc49zone8_clipped_selectedRoads.shp");
	
	file arrondisement_shape_file<-file("../includes/Paris BIG/arrondisements_projected_rgf93cc49zone8.shp");
	
	//file building_shape_file<-file("../includes/geofabrik_building_projected_rgf93cc49zone8_clipped.shp");
	file building_shape_file<-file("../includes/Paris BIG/geofabrik_building_projected_rgf93cc49zone8_clipped_selected.shp");
	
		
	geometry shape<-envelope(road_shape_file);
	
	
	init{
		create road from:road_shape_file;
		create arrondisement from:arrondisement_shape_file;
		create building from:building_shape_file;
		
	}
	
}


species road{
	rgb color<-#grey;
	
	aspect roadAspect{
		draw shape color:color;
	}
}

species arrondisement{
	rgb color<-#red;//color for the border
	
	aspect arrondisementAspect{
		
		//draw shape color:color border:#red;
		draw shape color:#transparent border:color;
	}
}


species building{
	rgb color<-#grey;//color for the border
	
	aspect buildingAspect{
		draw shape color: color border:#black;
	}
	
}


experiment parisData4SIM type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		
		display city_display type:3D{ //creates a 3D display 
		
			species road aspect:roadAspect; //adds the road species using the aspect named base to the display
			species arrondisement aspect:arrondisementAspect;
			species building aspect:buildingAspect;
			
		}
	}
}
