/**
* Name: Pollution
* Based on the internal empty template. 
* Author: romar
* Tags: 
* File status: Updated by Yassir @15:01
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
	int nb_cars <- 20;
	
	
	float coef_polutant <- 0.99 parameter: true min: 0.0 max: 1.0;
	int coef_car <- 1 parameter: true min:1 max 10;
	
	init{
		
		create building from: shape_file_buildings with:[type :: read("NATURE")]{
			if type = "Residential" {color<-#powderblue;}
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
			
			
			if flip(0.1){
				travel_mode_type <- "luxury";
				
			} else {
				travel_mode_type<- "normal";
				
			}
			
	}
	/*create cars number: nb_cars{
			
			location<-any_location_in(one_of(residential_building));
			
			//adding additional parameters in the initialisation of people agent
			
			speed <- rnd(min_speed, max_speed);
			start_work<- rnd (min_work_start,max_work_start);
			end_work <- rnd (min_work_end,max_work_end);
			living_place <- one_of(residential_building);
			working_place <- one_of(industrial_building);
			objective <- "resting";
			location <- any_location_in(living_place);
	}*/
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
	float polluttion_cant;
		
	
	aspect base{
		//draw shape color:blend(#black, #red, 1/polluttion_cant );
		
		if (polluttion_cant < 200 ){
			draw shape  color: #lime;
		}
	     else if (polluttion_cant >= 200 ) and (polluttion_cant <= 400 ){
			draw shape  color: #goldenrod;
		}
		 else if (polluttion_cant > 400 ){
			draw shape  color: #red width: 15 depth: polluttion_cant*0.05;
			
		}
	}
	reflex pollution {
		polluttion_cant<- polluttion_cant*coef_polutant;
		 
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
	string travel_mode; 
	string travel_mode_type; // luxury and normal 
	
	// added two new reflexes time to work and stop
	
	reflex time_to_work when: current_date.hour = start_work and objective = "resting"{
		objective <- "working";
		the_target <- any_location_in (working_place);
		if flip(0.3){
			travel_mode<-"car"; 
			color <- #red;
		
			
		}
		else {
			travel_mode<-"bike";
			color <- #green;
		}
	}
	
	reflex time_to_go_home when: current_date.hour = end_work and objective = "working"{
	objective <- "resting";
	the_target <- any_location_in (living_place);
	
	}
	
	//added the reflex move
	reflex move when: the_target != nil{
		
		do goto target: the_target on: the_graph;
		
		
		if (travel_mode = "car") {
			
		
			//adding pollution 
			list<geometry> segments <- current_path.segments;
			loop line over: segments {
				ask road(current_path agent_from_geometry line) { 
				polluttion_cant <- polluttion_cant + coef_car;
					}
			}
		}	
		if the_target = location {
			the_target <- nil ;
		}
	}
	
	aspect base{
		draw circle(10) color:color;
		
		if travel_mode_type = "normal"{
			draw circle(10) color:color;
		}
		else {
			draw triangle(50) color:#blue;
		}
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
			species road aspect: base transparency: 0.5;
			species people aspect: base; // adds people agent to the

		}

		/*display chart_display refresh: every(10 #cycles) {
			chart "People Objectif" type: pie style: exploded size: {1, 0.5} position: {0, 0.5} {
				data "Working" value: people count (each.objective = "working") color: #magenta;
				data "Resting" value: people count (each.objective = "resting") color: #blue;
			}

		}*/

		/*display chart_displaySERIES refresh: every(10 #cycles) {
			chart "People Objectif" type: pie style: exploded size: {1, 0.5} position: {0, 0.5} {
				data "Working" value: people count (each.objective = "working") color: #magenta;
				data "Resting" value: people count (each.objective = "resting") color: #blue;
			}

		}*/

	}

}


