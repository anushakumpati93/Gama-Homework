/**
 * Name: FestivalSimulation
 * Based on the internal empty template. 
 * Author: anusha & artemsliusarenko
 * Tags: FestivalSimulation
 */

model FestivalSimulation

global {
    point infoCenterLocation <- {50, 50};
    int numberOfGuests <- 10;
    int numberOfStores <- 4;
    int numberOfInfoCenters <- 1;

    init {
        create FestivalGuest number: numberOfGuests {
            location <- {rnd(100), rnd(100)};
            THIRST <- rnd(100);
            HUNGER <- rnd(100);
            infoCenterLocation <- infoCenterLocation;
        }

        create Store number: numberOfStores {
            location <- {rnd(100), rnd(100)};
            FOOD <- rnd(100);
            WATER <- rnd(100);
        }

        create InformationCenter number: numberOfInfoCenters {
            location <- infoCenterLocation;
        }

        loop counter from: 1 to: numberOfStores {
            Store store <- Store[counter - 1];
            store <- store.setName(counter);
        }

        loop counter from: 1 to: numberOfGuests {
            FestivalGuest my_agent <- FestivalGuest[counter - 1];
            my_agent <- my_agent.setName(counter);
        }
    }
}

species SecurityGuard skills: [moving] {

    point targetLocation <- nil; // not actual location target but location of anything to move towards, e.g., InfoCenter
    FestivalGuest target <- nil;

    aspect base {
        rgb agentColor <- rgb("blue");

        draw circle(1) color: agentColor;
    }

    action call(point pos) {
        targetLocation <- pos;
    }

    reflex idle when: targetLocation = nil and target = nil {
        do wander;
    }

    reflex gotoTarget when: targetLocation != nil and target = nil {
        do goto target: targetLocation;
    }

    reflex askInfoCenter when: !empty(InformationCenter at_distance distanceThreshold) and target = nil and targetLocation != nil {
        ask InformationCenter[0] {

            // pick target and remove target from InfoCenter list
            myself.target <- self.badGuests[0];
            remove myself.target from: self.badGuests;
            myself.targetLocation <- nil;
        }
    }

    reflex huntTarget when: target != nil {
        do goto target: target.location;
    }

    reflex killTarget when: (FestivalGuest at_distance distanceThreshold) contains target {
        ask target {
            do die;
        }
        target <- nil;
        write "target eliminated";
        ask InformationCenter[0] {
            if (length(self.badGuests) > 0) {
                myself.targetLocation <- self.location;
            }
        }
    }
}

aspect SecurityGuardAspect {
    draw box(5) at: self.location color: rgb("blue");
}


species FestivalGuest skills: [moving] {
    int THIRST <- 0;
    int HUNGER <- 0;
    point infoCenterLocation <- {50, 50};
    Store targetStore <- nil;
    rgb color <- #green;
    string personName <- "Undefined";

    action setName(int num) {
        personName <- "Person " + num;
    }

    reflex reportToInformationCenter when: (HUNGER = 100 or THIRST = 100) and targetStore = nil {
        do goto target: infoCenterLocation;
        ask InformationCenter at_distance 15 {
            self.reportBadBehavior;
        }
    }

    action reportBadBehavior {
        InformationCenter informationCenter <- InformationCenter[0];
        informationCenter.reportBadGuest(self);
    }

    reflex getHungryOrThurty when: (HUNGER < 100 or THIRST < 100) {
        int picker <- rnd(1);
        if (picker = 0 and HUNGER < 100){
            HUNGER <- HUNGER + rnd(100 - HUNGER);
        } else if (THIRST < 100) {
            THIRST <- THIRST + rnd(100 - THIRST);
        }

        if (HUNGER = 100 or THIRST = 100) {
            color <- #red;
        }
    }

    reflex goToStore when: (HUNGER = 100 or THIRST = 100) and targetStore != nil {
        do goto target: targetStore.location;
        ask Store at_distance 10 {
            write myself.personName + " reached store: " + myself.targetStore.storeName;
            if (self.FOOD <= 0 or self.WATER <= 0) {
                self.color <- #orange;
            }

            if (myself.HUNGER = 100 and self.FOOD > 0) {
                write myself.personName + " reduce hunger!";
                myself.HUNGER <- rnd(50);
                self.FOOD <- self.FOOD - 1;
            }

            if (myself.THIRST = 100 and self.WATER > 0) {
                write myself.personName + " reduce thirst!";
                myself.THIRST <- rnd(50);
                self.WATER <- self.WATER - 1;
            }

            write myself.personName + " forget store location.";
            myself.targetStore <- nil;

            if (myself.HUNGER < 100 and myself.THIRST < 100){
                myself.color <- #green;
            }
        }
    }

    reflex beIdle when: targetStore = nil and THIRST < 100 and HUNGER < 100 {
        color <- #green;
        do wander speed: speed + 2;
    }

    reflex goToInformationCenter when: (HUNGER = 100 or THIRST = 100) and targetStore = nil {
        do goto target: infoCenterLocation;
        ask InformationCenter at_distance 15 {
            int i <- rnd(length(self.stores) -1);
            write myself.personName + " go to store " + self.stores[i].storeName;
            write "Store: " + i;
            myself.targetStore <- self.stores[i];
        }
    }

    aspect default {
        draw sphere(2) at: location color: color;
    }
}

species InformationCenter {
    list<Store> stores <- list(); // Initialize an empty list

    action reportBadGuest(FestivalGuest badGuest) {
        SecurityGuard securityGuard <- SecurityGuard[0];
        securityGuard.removeBadGuest(badGuest);
    }

    aspect default {
        draw pyramid(15) at: location color: #black;
    }
}

species Store {
    int FOOD;
    int WATER;
    rgb color <- #yellow;
    string storeName <- "Undefined";

    reflex replenishSupplies when: FOOD = 0 and WATER = 0 {
        write storeName + " replenish supplies.";
        if (FOOD <= 0) {
            FOOD <- rnd(100);
        }

        if (WATER <= 0){
            WATER <- rnd(100);
        }
        color <- #yellow;
    }

    action setName(int num) {
        storeName <- "Store " + num;
    }

    aspect default {
        draw cube(8) at: location color: color;
    }
}

// Experiment definition placed correctly
experiment my_experiment type: gui {
    output {
        display myDisplay {
            species FestivalGuest aspect:default;
            species Store aspect:default;
            species InformationCenter aspect:default;
            species SecurityGuard aspect:default;
        }
    }
}
