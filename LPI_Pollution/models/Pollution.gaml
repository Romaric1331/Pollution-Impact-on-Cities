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
	//int nba <- 20 parameter: true min: 10 max: 1000; //adds a slider for the number of agents

	// float pbc <- 0.5 parameter:true min:0.0 max:1.0; //gives a slider to randomly adjust the ratio of bicycle users:car users
	float studentProb <- 0.5; //parameter: true; //Probability for a student profile
	float lowIncomeProb <- 0.5; //parameter: true; //Probability for a low-income profile
	float highIncomeProb <- 0.5;// parameter: true; //Probability for a low-income profile
	file shape_file_buildings <- file("../includes/building.shp");
	file shape_file_roads <- file("../includes/road.shp");
	file shape_file_bounds <- file("../includes/bounds.shp");
	geometry shape <- envelope(shape_file_bounds);
	float step <- 10 #m; //a timestep of 10 mins
	int nb_people <- 100;

	//adding these new parameters
	date starting_date <- date("2019-09-01-06-00-00");
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16;
	int max_work_end <- 20;
	float min_speed <- 1.0 #km / #h;
	float max_speed <- 5.0 #km / #h;
	graph the_graph;
	int nb_cars <- 20;
	float pollute <- 0.02;
	float coef_polutant <- 0.95 parameter: true min: 0.0 max: 1.0;
	int coef_car <- 5 parameter: true min: 0 max: 10;
	
	// Pollution evaluation
	float overall_pol_threshold <- 200 parameter:true min:100 max:500;

	init {
		create building from: shape_file_buildings with: [type::read("NATURE")] {
			if type = "Residential" {
				color <- #sienna;
			}

		}

		create road from: shape_file_roads;
		the_graph <- as_edge_graph(road);

		// create profiles

		//The profiles are: students, low-income, high-income
		int number_of_students <- int(length(people) * studentProb);
		list students <- number_of_students among people; //get me a list of cowards of size with the given proportion of cowards
		
		int number_of_lowIncomes <- int(length(people) * lowIncomeProb);
		list lowIncomes <- number_of_lowIncomes among people; //get me a list of cowards of size with the given proportion of cowards
		
		int number_of_highIncomes <- int(length(people) * highIncomeProb);
		list highIncomes <- number_of_highIncomes among people; //get me a list of cowards of size with the given proportion of cowards
		

		//create a list of budiling which are residentials
		list<building> residential_building <- building where (each.type = "Residential");

		// list of industrial building
		list<building> industrial_building <- building where (each.type = "Industrial");
		create people number: nb_people { //this is executed for each agent
			transport_choice <- flip(0.5) ? "bicycle" : "car"; //This agent will choose either a bicycle or a car
			//write (self.transport_choice); // print this agent's transport choice
			location <- any_location_in(one_of(residential_building));
			profile <- rnd_choice(["student"::studentProb, "low-income"::lowIncomeProb, "high-income"::highIncomeProb]);

			//adding additional parameters in the initialisation of people agent


			//speed <- rnd(min_speed, max_speed);
			start_work <- rnd(min_work_start, max_work_start);
			end_work <- rnd(min_work_end, max_work_end);
			living_place <- one_of(residential_building);
			working_place <- one_of(industrial_building);
			objective <- "resting";
			location <- any_location_in(living_place);
			if flip(0.1) {
				travel_mode_type <- "luxury";
			} else {
				travel_mode_type <- "normal";
			}

		}

	
	}
	
	float pollution_value;
	reflex pol { pollution_value <- mean(road collect (each.polluttion_cant)); }

}

species building {
	string type;
	rgb color <- #gray;

	aspect base {
		draw shape color: color;
	}

}

species road {
	float polluttion_cant;

	aspect base {

	//draw shape color:blend(#black, #red, 1/polluttion_cant );
		if (polluttion_cant < 50) {
			draw shape color: #lime;
		} else if (polluttion_cant >= 50) and (polluttion_cant <= 200) {
			draw shape color: #goldenrod;
		} else if (polluttion_cant > 200) {
			draw shape color: #red width: 15 depth: polluttion_cant * 0.1;
		} }

	reflex pollution {
		polluttion_cant <- polluttion_cant * coef_polutant;
	} }

species people skills: [moving] {
	string transport_choice; //Each agent can choose thier mode of transport
	string profile;
	rgb color <- #yellow;

	//added the following attributes
	building living_place <- nil;
	building working_place <- nil;
	int start_work;
	int end_work;
	string objective;
	point the_target <- nil;
	string travel_mode <- "car";
	string travel_mode_type; // luxury and normal
	
	float pollution_thresh -> overall_pol_threshold;


	reflex gogo when:the_target = nil {
		objective <- flip(0.2) ? "resting" : "working";
		the_target <- any_location_in(any(building));
		if travel_mode = nil or travel_mode = "" {
			if pollution_value > pollution_thresh {
				travel_mode <- "car";
				color <- #red;
			} else {
				travel_mode <- "bicycle";
				color <- #green;
			}
		}
	}

	// added two new reflexes time to work and stop
	reflex time_to_work when:false and current_date.hour = start_work and objective = "resting" {
		objective <- "working";
		the_target <- any_location_in(working_place);
		if travel_mode = nil or travel_mode = "" {
			if pollution_value > pollution_thresh {
				travel_mode <- "car";
				color <- #red;
			} else {
				travel_mode <- "bicycle";
				color <- #green;
			}
		}
	}

	reflex time_to_go_home when:false and current_date.hour = end_work and objective = "working" {
		objective <- "resting";
		the_target <- any_location_in(living_place);
	}

	//added the reflex move
	reflex move when: the_target != nil {
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
			the_target <- nil;
		}
		if objective = "resting" { travel_mode <- nil; }

	}

	aspect base {
		draw circle(10) color: color;
		if travel_mode_type = "normal" {
			draw circle(10) color: color;
		} else {
			draw triangle(50) color: #blue;
		}

	}

	aspect profile {
		if profile = "student" {
			draw triangle(20) color: #green;
		} else if profile = "low-income" {
			draw circle(20) color: #yellow;
		} else {
			draw square(20) color: #blue;
		}

	}

	aspect transport_choice //Displays the choices of people for transport mode
	{
		if travel_mode = "bicycle" //agent using bicycle
		{
			draw triangle(20) color: #green;
		} else //agent using car
		{
			draw rectangle(10, 20) color: #red;
		}

	}

}

experiment NewModel type: gui {

/** Insert here the definition of the input and output of the model */
//	parameter "Shapefile for buildings:" var: shape_file_buildings category: "GIS";
//	parameter "Shapefile for roads:" var: shape_file_roads category: "GIS";
//	parameter "Shapefile for bounds:" var: shape_file_bounds category: "GIS";
	parameter "Number if people agents" var: nb_people category: "People" min:100 max:1000; //adding for people
	
	output {
//		display people_profile type: 3d {
//			overlay position: { 5, 5 } size: { 180 #px, 100 #px } background: pollution_value < 200 ? #green : (pollution_value < 500 ? #orange : #red) 
//				transparency: 0.5 border: #black rounded: true {
//				draw "Pollution is "+(pollution_value < 200 ? "good" : (pollution_value < 500 ? "middle" : "bad")) color:#black at:{ 15, 35 } font:font(20);
//				draw string(int(pollution_value)) color:#black at:{ 35, 75 } font:font(40,"bold"); 
//			}
//			species building aspect: base;
//			species road aspect: base;
//			species people aspect: profile;
//		}

		display city_transportchoice type: 3d {
				overlay position: { 5, 5 } size: { 180 #px, 100 #px } background: pollution_value < 200 ? #green : (pollution_value < 500 ? #orange : #red) 
				transparency: 0.5 border: #black rounded: true {
				draw "Pollution is "+(pollution_value < 200 ? "good" : (pollution_value < 500 ? "middle" : "bad")) color:#black at:{ 15, 35 } font:font(20);
				draw string(int(pollution_value)) color:#black at:{ 35, 100 } font:font(30); 
			}
			species building aspect: base;
			species road aspect: base transparency: 0.5;
			species people aspect: transport_choice; //This aspect only shows the people's transport choices

		}

		display transport_proportion type: 2d{
			chart "transport" type:series {
				data "bike" value:people count (each.travel_mode="bicycle") color:#green;
				data "car" value:people count (each.travel_mode="car") color:#red;
			}
		}

	}

}