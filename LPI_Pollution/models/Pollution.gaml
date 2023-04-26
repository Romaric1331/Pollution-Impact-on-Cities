/**
* Name: Pollution
* Based on the internal empty template. 
* Author: romar
* Tags: 
*/


model Pollution

/* Insert your model definition here */
global {
	/** Insert the global definitions, variables and actions here */
	
	file shape_file_buildings <- file("../includes/building.shp");
	file shape_file_roads <- file("../includes/road.shp");
	file shape_file_bounds <- file("../includes/bounds.shp");
	geometry shape <- envelope (shape_file_bounds);
	float step <- 10#m; //a timestep of 10 mins
	
	int nb_people<-100;
	
	//adding these new parameters 
	
	date starting_date <- date("2019-09-01-00-00-00");
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <-16;
	int max_work_end <-20;
	float min_speed <- 1.0 #km /#h;
	float max_speed <-5.0 #km / #h;
	graph the_graph;
	
	
	init{
		
		create building from: shape_file_buildings with:[type :: read("NATURE")]{
			if type = "Residential" {color<-#blue;}
		}
		
		create road from: shape_file_roads;
		
		the_graph <- as_edge_graph(road);
		
		// create car 
		
		
		
		//create a list of budiling which are residentials 
		
		list<building> residential_building <- building where (each.type="Residential");
		
		// list of industrial building
		list<building> industrial_building <- building where (each.type="Industrial");
		
		
		create people number: nb_people{
			
			location<-any_location_in(one_of(residential_building));
			
			//adding additional parameters in the initialisation of people agent
			
			speed <- rnd(min_speed, max_speed);
			start_work<- rnd (min_work_start,max_work_start);
			end_work <- rnd (min_work_end,max_work_end);
			living_place <- one_of(residential_building);
			working_place <- one_of(industrial_building);
			objective <- "resting";
			location <- any_location_in(living_place);
	}
}
}

species building{
	string type;
	rgb color <- #gray;
	
	aspect base{
		draw shape color:color;
	}
}

species road{
	
	
	aspect base{
		draw shape color:color;
	}
}


species people skills:[moving] {
	
	rgb color <- #yellow;
	
	//added the following attributes
	building living_place <- nil;
	building working_place <- nil;
	int start_work;
	int end_work;
	string objective;
	point the_target <- nil;
	
	// added two new reflexes time to work and stop
	
	reflex time_to_work when: current_date.hour = start_work and objective = "resting"{
	objective <- "working";
	the_target <- any_location_in (working_place);
	}
	
	reflex time_to_go_home when: current_date.hour = end_work and objective = "working"{
	objective <- "resting";
	the_target <- any_location_in (living_place);
	}
	
	//added the reflex move
	reflex move when: the_target != nil{
		
		do goto target: the_target on: the_graph;
		
		if the_target = location {
			the_target <- nil;
		}
	}
	
	aspect base{
		draw circle(10) color:color;
	}
}


experiment NewModel type: gui {

/** Insert here the definition of the input and output of the model */
	parameter "Shapefile for buildings:" var: shape_file_buildings category: "GIS";
	parameter "Shapefile for roads:" var: shape_file_roads category: "GIS";
	parameter "Shapefile for bounds:" var: shape_file_bounds category: "GIS";
	parameter "Number if people agents" var: nb_people category: "People"; //adding for people
	output {
		display city_display type: 3d {
			species building aspect: base;
			species road aspect: base;
			species people aspect: base; // adds people agent to the 
		}

		display chart_display refresh: every(10 #cycles) {
			chart "People Objectif" type: pie style: exploded size: {1, 0.5} position: {0, 0.5} {
				data "Working" value: people count (each.objective = "working") color: #magenta;
				data "Resting" value: people count (each.objective = "resting") color: #blue;
			}

		}

		display chart_displaySERIES refresh: every(10 #cycles) {
			chart "People Objectif" type: pie style: exploded size: {1, 0.5} position: {0, 0.5} {
				data "Working" value: people count (each.objective = "working") color: #magenta;
				data "Resting" value: people count (each.objective = "resting") color: #blue;
			}

		}

	}

}


