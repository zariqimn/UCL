clear all
clc
height_engine_room = 2;
height_pack = 654e-3;
% minimum energy capacity
n_trip = input('Number of trips in a day: '); %number of trips in a
day%
n_stops = n_trip - 1; %number of interval stops
stop_duration = input('duration of stop in hours: ');
charging_duration = stop_duration*0.5;
charging_power = input('charging power in kW: ');
battery_capacity = charging_duration*charging_power;
%
width_of_ship = 19;
width_engine_room = 19*0.8;
max_available_horiz = width_engine_room;
available_space = width_engine_room;
width_pack = 5e-1;
max_x_pack = width_engine_room/width_pack;
horiz_stack = 0;
length_engine_room = 0.8*90;
available_length = length_engine_room;
length_pack = 2370e-3;
width_stack = 0;
max_z_pack = available_length / length_pack;
height_engine_room = 2;
available_height = height_engine_room;
height_stack = 0;
height_pack = 654e-3;
max_y_pack = available_height / height_pack;
energy_density = 177; %Wh/kg
volumetric_density = 100; %l/Wh
%%
for i = 0: max_x_pack
if available_space > width_pack
available_space = available_space - width_pack;
horiz_stack = horiz_stack + 1;
end
end
for j = 0: max_z_pack
if available_length > length_pack
available_length = available_length - length_pack;
width_stack = width_stack + 1;
32
end
end
for k = 0:max_y_pack
if available_height > height_pack
available_height = available_height - height_pack;
height_stack = height_stack + 1;
end
end
total_potential_stack = height_stack * horiz_stack *
width_stack;
total_potential_capacity = 77*total_potential_stack; %in kWh
max_volume = total_potential_capacity/(volumetric_density);
% in m^3
max_weight = total_potential_capacity/(energy_density); % in
tonnes
%%
% Case 1: format (hours, speed)
file_name = input('file name: ','s'); %in .xlsx
speed_profile = readmatrix(file_name);
length_data = length(speed_profile);
time = speed_profile(1:length_data,1);
speed = speed_profile(1:length_data,2);
voyage_time = sum(time(length_data));
daily_operation = (n_trip*voyage_time) + (stop_duration*n_stops);
available_time = 24 - daily_operation;
% power demand profile
n = length(speed_profile);
k = 0.5*1026*0.00004*60.8;
propulsion_power_demand = k*speed.^3;
time_gap(1)=0;
for i = 2:1: n
time_gap(i,1) = time(i)-time(i-1);
p_energy_demand(i,1) =
(propulsion_power_demand(i)+propulsion_power_demand(i-
1))*time_gap(i,1)*0.5;
end
p_energy_voyage = sum(p_energy_demand);
hotel_energy = p_energy_voyage*0.42/0.58;
hotel_power = hotel_energy/voyage_time;
for i = 1:1:n
energy_demand(i,1) =
p_energy_demand(i,1)+(hotel_power*time_gap(i,1));
end
energy_voyage = sum(energy_demand);% voyage energy demand
%%
total_n_energy_voyage = repmat(energy_demand,n_trip,1);
33
%%
battery_shore = zeros(n_stops,n_stops+1);
for g = n_stops:-1:1
battery_shore(1:g,g+1)=battery_capacity;
end
battery_shore= flipud(battery_shore);
%%
for o = 1:1: n_stops+1
total_energy(o)= n_trip*energy_voyage - (o-
1)*battery_capacity;
time_to_charge(o) = total_energy(o)/charging_power;
feasibility_time(o) = available_time - time_to_charge(o);
time_f = feasibility_time(o);
max_SOC = total_energy(o)*0.8/0.6;
battery_full(o) = max_SOC/0.8;
min_SOC = battery_full(o)*0.2;
if time_f > 0 && battery_full(o)>1.5*energy_voyage
poss_stop(o)=o-1;
total_e_battery(1,o)=max_SOC;
for b = 2:1:length(total_n_energy_voyage)
total_e_battery(b,o)=total_e_battery(b-1,o)-
total_n_energy_voyage(b);
if rem(b,length(energy_demand)) == 1
total_e_battery(b,o)=
total_e_battery(b,o)+battery_shore(floor(b/length(energy_demand)),o)
;
end
end
end
end
if exist('poss_stop') ==0
if feasibility_time(o)<0
display('time not feasible, please choose higher
charging power');
return;
elseif battery_full(o)<0
display('Charging power too high');
return;
end
end
total_possible_stops = nonzeros(poss_stop) ;
display('There are several number of charging stops possible:
');
display(total_possible_stops);
n_stop_preferred = input('select the preferred number: ');
total_e_battery = total_e_battery(:,n_stop_preferred+1);
x_data = 1:length(total_e_battery);
battery_selected = battery_full(1,n_stop_preferred+1);
battery_size = 0.001*battery_selected*1000/100;
battery_weight = battery_selected*5.6/1000;
34
if battery_size > max_volume || battery_weight > max_weight
display('this size is not possible, please choose smaller
battery ie; less stops');
return
end
%% techno-economic analysis
feasible_battery_energy = nonzeros(total_e_battery(1,:));
demand_daily = energy_voyage*n_trip;
trips_yearly = 360*n_trip;
demand_yearly = trips_yearly*energy_voyage;
electricity_price = readmatrix('electricity_price.xlsx');
fuel_price = readmatrix('fuel_price.xlsx');
diesel_energydensity = 9.7;
diesel_engine_eff = 0.45;
CO2kg_perlit_diesel = 2.68;
carbon_rate = 18;
%%
years=2022:1:2032;
shore_battery = battery_capacity*1.5*2/0.6;
battery_cost_pound = input('cost of battery £/kWh : ');
battery_cost = 132*(battery_selected+shore_battery);
BMS_cost = battery_cost*0.5;
retrofit_cost = BMS_cost + battery_cost;
investment(1,1) = retrofit_cost;
investment(1,2:11)= 0;
inflation_rate = 0.05;
PV(1) = -investment(1,1);
for year = 1:1:10
elect_cost(year) =
demand_yearly*electricity_price(year+1,2)/98;
fuel_cost(year) =
demand_yearly*fuel_price(year+1,2)/(100*diesel_energydensity*diesel_
engine_eff);
CO2_emission(year)=
CO2kg_perlit_diesel*demand_yearly/(diesel_energydensity*diesel_engin
e_eff);
carbon_tax(year)= carbon_rate*CO2_emission(year)/1000;
cost_saved(year)= fuel_cost(year)+carbon_tax(year)-
elect_cost(year);
maintenance(year) = battery_cost*0.02;
discount_factor =1/((1+0.05)^year);
cash_flow(year) = cost_saved(year)-maintenance(year);
discounted_cf(year)= cash_flow(year)*discount_factor;
if year == 1
35
PV(year+1) = PV(1)+discounted_cf(year);
else
PV(year+1) = PV(year)+discounted_cf(year);
end
end
cumul_cf = sum(discounted_cf);
NPV = PV(1) + cumul_cf;
TE = [years;investment;0,cost_saved;0,maintenance;
0,cash_flow;0,discounted_cf;PV];
TE(5:6,1)=PV(1);
TE=array2table(TE,'RowNames',{'year','investments','cost
savings','maintenance','cash flow','discounted cash flow','Present
Value'});
firstpos = find(PV>0,1);
lastnegative = firstpos - 1;
payback_p = lastnegative + ((0-PV(lastnegative))/(PV(firstpos)-
PV(lastnegative)));
result = input('display full techno-economic spec? 1/0 :');
Ferry_battery_spec = [n_trip;energy_voyage;battery_selected;
battery_size; battery_weight; battery_capacity;n_stop_preferred;
NPV;payback_p;retrofit_cost];
Ferry_battery_spec =
array2table(Ferry_battery_spec,'RowNames',{'Number of trips','Trip
demand in kWh','Battery Capacity in kWh', 'Battery size in cubic
meter','Battery Weight in tonne','Shore Battery in kWh', 'Number of
stops','NPV in £','Payback Period in years','Initial Investment in
£'});
if result ==1
display(Ferry_battery_spec);
plot(x_data,total_e_battery);
title("Energy Intake at "+ n_stop_preferred +" charging
stops");
xlabel("data points");
ylabel("Energy Capacity in kWh");
yline(battery_selected*0.8);
yline(battery_selected*0.2);
return
end