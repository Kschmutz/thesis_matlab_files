%automate simulations and solve for coefficients yielding best results
%Fuzzy Controller Split-u Test
%stop simulation command:
%set_param(gcs, 'SimulationCommand', 'stop')

%prevent warnings from showing in command window
warning('off','all');

Simulation_Count = 0; %Counts the simulation iteration number

gdp = 0;   %Number of actual saved control gain points (initialized to zero)
nsp = 10;  %Max number of saved control gain points
stop_time = 3.001;   %simulation run time (HAS TO BE CHANGED HERE AND ALSO IN MODEL FILE)
min_Vx = repmat(100, 1, nsp);
Yaw_Ctrl_Gain_Lowest = repmat(100, 1, nsp);
Slip_Ratio_Ctrl_Gain_Lowest = repmat(100, 1, nsp);

VMC_Vx = repmat(100, stop_time*1000, nsp);
VMC_Vy = repmat(100, stop_time*1000, nsp);
VMC_r  = repmat(100, stop_time*1000, nsp);

%Set up sim values
addpath('M_Files/Sim_Setup'); 
run('AWD_Test_W_FUZ_Control.m');

%Add path for sim files
addpath('All_Combined');
addpath('Fuzzy_Controller_Files');

sim_pts = 100;
for cntr=80:sim_pts
    for cntr1=80:sim_pts
        %update workspace
        %whos
        
        %make edits to sim values
        %Lat_Accel_Err_Gain = (cntr3/(2*sim_pts_la) + 0.5)*1
        Yaw_Ctrl_Gain = (cntr/sim_pts)*1 
        Slip_Ratio_Ctrl_Gain = (cntr1/sim_pts)*1 
        
        %simulate and collect data
        Simulation_Count = Simulation_Count + 1
        %assignin('base', 'Simulation_Count', Simulation_Count)
        sim('All_Combined/AWD_EV_MODEL_rev2.mdl')%,'CaptureErrors', 'on')
        
        %analyze data and make decision
        min_Vx_new = min(abs(VMC(:,16)));  %Check min Vx
        if  VMC(3000,16) < 10 ...            %make sure velocity is less than 5m/s by 5s
                && max(abs(VMC(:,17))) < 1 ...     %make sure Vy lower than 1m/s the entire time.
                && max(VMC(:,18)) < 0.08;    % make sure yaw rate does not exceed 0.08rad(4.5deg)/s
            if min_Vx_new < min_Vx(1);
                for s = 1:(nsp-1)
                    min_Vx_X(1,s+1) = min_Vx(1,s);
                    Yaw_Ctrl_Gain_Lowest_X(1,s+1) = Yaw_Ctrl_Gain_Lowest(1,s);
                    Slip_Ratio_Ctrl_Gain_Lowest_X(1,s+1) = Slip_Ratio_Ctrl_Gain_Lowest(1,s);
                    
                    VMC_Vx_X(:,s+1) = VMC_Vx(:,s);
                    VMC_Vy_X(:,s+1) = VMC_Vy(:,s);
                    VMC_r_X (:,s+1) = VMC_r (:,s);
                end
                %Place value in 1st slot of dummy (X) arrays
                min_Vx_X(1,1) = min_Vx_new;
                Yaw_Ctrl_Gain_Lowest_X(1,1) = Yaw_Ctrl_Gain;
                Slip_Ratio_Ctrl_Gain_Lowest_X(1,1) = Slip_Ratio_Ctrl_Gain;
                
                VMC_Vx_X(:,1) = VMC(:,16);
                VMC_Vy_X(:,1) = VMC(:,17);
                VMC_r_X (:,1) = VMC(:,18);
                
                %set newly constructed arrays to variable
                min_Vx = min_Vx_X;
                Yaw_Ctrl_Gain_Lowest = Yaw_Ctrl_Gain_Lowest_X;
                Slip_Ratio_Ctrl_Gain_Lowest = Slip_Ratio_Ctrl_Gain_Lowest_X;
                
                Gains(1,:) = Yaw_Ctrl_Gain_Lowest_X;
                Gains(2,:) = Slip_Ratio_Ctrl_Gain_Lowest_X;
                
                VMC_Vx = VMC_Vx_X;
                VMC_Vy = VMC_Vy_X;
                VMC_r  = VMC_r_X;
                
                gdp = gdp + 1;
                
                break
            else
                dummy=1;
            end
            
            
        else
            dummy=1;
            
        end
    end
end

%save workspace to file

Filename_c = sprintf('Fuzzy_Control_ABS_Test_%s.mat', datestr(now,'mm-dd-yyyy_HH-MM'));
save(Filename_c);

figure % new figure
hold on
ax1 = subplot(3,1,1); % top subplot
hold on
ax2 = subplot(3,1,2); % bottom subplot
hold on
ax3 = subplot(3,1,3); % bottom subplot

for m = 1:gdp
    hold on
    plot(ax1,VMC(:,10),VMC_Vx (:,m))
    plot(ax2,VMC(:,10),VMC_Vy (:,m))
    plot(ax3,VMC(:,10),VMC_r (:,m))
end

Filename_fig = sprintf('Fuzzy_Control_ABS_Test_fig_%s.fig', datestr(now,'mm-dd-yyyy_HH-MM'));
savefig(Filename_fig);