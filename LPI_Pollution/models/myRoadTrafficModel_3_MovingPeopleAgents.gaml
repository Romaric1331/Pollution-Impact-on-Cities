/**
* Name: myRoadTrafficModel
* Based on the internal skeleton template. 
* Author: Julius
* Tags: 
*/

model myRoadTrafficModel

global {
	/** Insert the global definitions, variables and actions here */
	
	//file shape_file_buildings<-file("../includes/building.shp");
	//file shape_file_roads<-file("../includes/road.shp");
	
	//file shape_file_buildings<-file("../includes/geofabrik_building_projected_rgf93cc49zone8_clipped.shp");
	//file shape_file_roads<-file("../includes/geofabrik_roads_projected_rgf93cc49zone8_clipped.shp");
	
	//file shape_file_buildings<-file("../includes/geofabrik_building_projected_rgf93cc49zone8_clipped_selected.shp");
	//file shape_file_roads<-file("../includes/geofabrik_roads_projected_rgf93cc49zone8_clipped_selectedRoads.shp");
	
	file shape_file_buildings<-file("../includes/Paris BIG/geofabrik_building_projected_rgf93cc49zone8_clipped_selected_trim.shp");
	//file shape_file_roads<-file("../includes/geofabrik_roads_projected_rgf93cc49zone8_clipped_selectedRoads_trim.shp");
	
	
	//"../includes/geofabrik_roads_projected_rgf93cc49zone8_clipped_selectedRoads_trim_clean.shp"
	file shape_file_roads<-file("../includes/Paris BIG/geofabrik_roads_projected_rgf93cc49zone8_clipped_selectedRoads_trim_clean.shp");
	
	
	
	
	//file shape_file_bounds<-file("../includes/bounds.shp"); //bounds or extents of the display
	
	
	//geometry shape<-envelope(shape_file_bounds); //defining the geometry/bounds/extents of the model
	geometry shape<-envelope(shape_file_roads); //defining the geometry/bounds/extents of the model
	
	float step<-0.5#mn; //assigning a timestep of 10 minute intervals
	int nb_people<-100; //set number of people to 100
	
	//adding these new parameters for the people agent
	date starting_date <- date("2019-09-01-00-00-00");
    int min_work_start <- 6;
    int max_work_start <- 8;
    int min_work_end <- 16; 
    int max_work_end <- 20; 
    float min_speed <- 1.0 #km / #h;
    float max_speed <- 5.0 #km / #h; 
    graph the_graph; //this resolves the previous error on the_graph, since this is now declared here
                     //this will be used to set the road as a graph
	
	

	init{
		
		//we create the building from the building shapefile, initialising it with the field in the shapefile
		//named "NATURE". we assign the values to the variable "type". 
		//To assign the color, if the value of type="Industrial", then we set the color to blue
		
		//create building from: shape_file_buildings with:[type::read("NATURE")]{
		create building from: shape_file_buildings with:[type::read("type")]{	
			if type="apartments"{
				color<-#dodgerblue;
			} else if type!="apartments"{
				color<-#red;
			} else {
				color<-#grey;
			}
		}
		
		//creating the road agents from the roads shapefile
		
		create road from:shape_file_roads;
	
        the_graph <- as_edge_graph(road); //initialise the road as graph
		
		
		//create a list of buildings which are residential 
		//list<building> residential_buildings<-building where (each.type="residential");
		list<building> residential_buildings<-building where (each.type="apartments");
		
		
		//adding the list of industrial buildings
		list<building>  industrial_buildings <- building  where (each.type!="apartments") ;
		
		
		//create people agents in the residential buildings
		
		create people number:nb_people{
			
			location<-any_location_in(one_of(residential_buildings));
			
			//adding additional parameters in the initialisation of people agents
			
			speed <- rnd(min_speed, max_speed);
        	start_work <- rnd (min_work_start, max_work_start);
        	end_work <- rnd(min_work_end, max_work_end);
            living_place <- one_of(residential_buildings) ;
            working_place <- one_of(industrial_buildings) ;
            objective <- "resting";
            location <- any_location_in (living_place); 
			
		}	
	}
		
}

species building{
	
	string type; //attribute type of the building (residential, industrial)
	rgb color<-#gray; //attribute color of the building 
	
	aspect base{    //we define this aspect called "base" 
		
		draw shape color:color;  //here we draw the shape with the color attribute to the color facet :)
		
	}
	
}

species road{
	
	rgb color<-#lightgrey; //attribute color of the road in the display
	
	aspect base{ //defining this aspect called "base" for the road
		
		draw shape color:color; //here we draw the shape with the color attribute to the color facet :) 
		
	}
	
}


species people skills:[moving]{   //add the skill moving to the people agent
	
	rgb color <- #yellow;
	
	//added the following attributes
	building living_place <- nil ; //currently these are nil
    building working_place <- nil ; //currently these are nil
    int start_work ;
    int end_work  ;
    string objective ; 
    point the_target <- nil ; //currently these are nil
    
    
    
    //added two new reflexes time to work, and time to go home
    
    reflex time_to_work when: current_date.hour = start_work and objective = "resting" {
        objective <- "working" ;
        the_target <- any_location_in (working_place);
    }
        
    reflex time_to_go_home when: current_date.hour = end_work and objective = "working" {
        objective <- "resting" ;
        the_target <- any_location_in (living_place); 
    } 
    
	
	//added the reflex move
	reflex move when: the_target != nil {
		
	    do goto target: the_target on: the_graph ; //currently this is an error, we will define 
	                                               //the_graph in the next step setting parameters
	    
	    if the_target = location {
	        the_target <- nil ;
	   }
    
    }
	
	
	aspect base{
		
		draw circle(100)color:color border:#black;
	}
	
} 





experiment myRoadTrafficModel type: gui {
	/** Insert here the definition of the input and output of the model */
	
	parameter "Shapefile for buildings: " var: shape_file_buildings category: "GIS";
	parameter "Shapefile for roads: " var: shape_file_roads category: "GIS";
	//parameter "Shapefile for the bounds" var: shape_file_bounds category:"GIS";
	parameter "Number of people agents" var: nb_people category:"People"; //adding for people agents
	
	//adding new parameters for the people agent's detailed behaviour
	
	parameter "Earliest hour to start work" var: min_work_start category: "People" min: 2 max: 8;
    parameter "Latest hour to start work" var: max_work_start category: "People" min: 8 max: 12;
    parameter "Earliest hour to end work" var: min_work_end category: "People" min: 12 max: 16;
    parameter "Latest hour to end work" var: max_work_end category: "People" min: 16 max: 23;
    parameter "minimal speed" var: min_speed category: "People" min: 0.1 #km/#h ;
    parameter "maximal speed" var: max_speed category: "People" max: 10 #km/#h;
	
	
	output {
		
		display city_display type:3D{ //creates a 3D display 
			
			species building aspect:base; //adds the building species using the aspect named base to the display
			species road aspect:base; //adds the road species using the aspect named base to the display
		
			species people aspect:base; //adds people agent to the display	
			
		}
		
	/*	
		display chart_display refresh: every(10#cycles) {
			
			chart "People Objectif" type: pie  {
                data "Working" value: people count (each.objective="working") color: #magenta ;
                data "Resting" value: people count (each.objective="resting") color: #blue ;
            }
			
		}
	*/
		
	///*	
//		display chart_display refresh: every(10#cycles) {
//			
//			//chart "People Objectif" type: pie style: exploded size: {1, 0.5} position: {0, 0.5}{
//			chart "People Objectif" type: pie{	
//                data "Working" value: people count (each.objective="working") color: #magenta ;
//                data "Resting" value: people count (each.objective="resting") color: #blue ;
//            }
//			
//		}
   //*/		
	
	///*
//		display chart_displaySERIES refresh: every(100#cycles) {
//			
//			//chart "People Objectif" type: series style: exploded size: {1, 0.5} position: {0, 0.5}{
//			chart "People Objectif" type: series{	
//                data "Working" value: people count (each.objective="working") color: #magenta ;
//                data "Resting" value: people count (each.objective="resting") color: #blue ;
//            }
//			
//		}
//	
//	//*/
	}
	
}
