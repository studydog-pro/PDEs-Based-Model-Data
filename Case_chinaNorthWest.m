function [mpc, gtd] = Case_chinaNorthWest()
% v6:该案例对应的是电氢联合优化潮流，有ptg和windfarm
% 并且在mpce基础上修改ptg位置，来人为制造阻塞
% v7: 换了ptg的接入点
% 20221230：删去了dispatchable load，还是写在优化模型里作为单独的变量比较好，否则容易造成误解

%CASE24_IEEE_RTS  Power flow data for the IEEE RELIABILITY TEST SYSTEM.
%   Please see CASEFORMAT for details on the case file format.
%
%   This system data is from the IEEE RELIABILITY TEST SYSTEM, see
%
%   IEEE Reliability Test System Task Force of the Applications of
%   Probability Methods Subcommittee, "IEEE reliability test system,"
%   IEEE Transactions on Power Apparatus and Systems, Vol. 98, No. 6,
%   Nov./Dec. 1979, pp. 2047-2054.
%
%   IEEE Reliability Test System Task Force of Applications of
%   Probability Methods Subcommittee, "IEEE reliability test system-96,"
%   IEEE Transactions on Power Systems, Vol. 14, No. 3, Aug. 1999,
%   pp. 1010-1020.
%
%   Cost data is from Web site run by Georgia Tech Power Systems Control
%   and Automation Laboratory:
%
%       http://pscal.ece.gatech.edu/testsys/index.html
%
%   MATPOWER case file data provided by Bruce Wollenberg.

%   MATPOWER

%% MATPOWER Case Format : Version 2
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = readmatrix('mpc.xlsx','Sheet','bus','Range','A2:M198');%'airlinesmall_subset.xlsx','Sheet','2007','Range','A2:E11'
mpc.Pd = [mpc.bus(:,1),mpc.bus(:,3)];

%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin	Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf	%	Unit Code
mpc.gen = readmatrix('mpc.xlsx','Sheet','gen','Range','A2:U33');
mpc.gfuIndex = [2 4 5 7 10 12 21]';% unit index
mpc.windfarmIndex = [29]; % 400 MW
% mpc.gen(mpc.windfarmIndex,9) = 1000; % 1000 MW
genFlag = zeros(size(mpc.gen,1),1);
genFlag(mpc.gfuIndex) = 1;
genFlag(mpc.windfarmIndex) = 2;
mpc.gen = [mpc.gen, genFlag];
%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = readmatrix('mpc.xlsx','Sheet','branch','Range','A2:M274');
%

%%-----  OPF Data  -----%%
%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = readmatrix('mpc.xlsx','Sheet','gencost','Range','A2:G33');
mpc.gencost([mpc.gfuIndex;mpc.windfarmIndex],[2:7])=0;
mpc.gencost(:,5) = 0; % eliminate square

%% gas bus data
%1st col: bus index 
%2nd col: bus type: 1 for gas system-in bus (usually a  gas source) 'Q' bus, 2 for gas load constant 'P'(for the actual load is not determined before gas flow）
%bus, 3 for connection bus （doesn't have gas source or load)
%3rd col: Pd(Mm3/day)66.25 %4th col: p0(bar) 
%5th col: pmin %6th col: pmax(bar)
Gbus = readmatrix('mpc.xlsx','Sheet','Gbus','Range','A2:F172');

% the gas load of GFU has already been considered in the GEOPF, therefore
% no need to add additional load here
mpc.Gbus=Gbus;
%% gas pipeline data
%1:from bus %2:to bus %3:Cij %4:fmin %5:fmmax(Mm3/day)
Gline = readmatrix('mpc.xlsx','Sheet','Gline','Range','A2:G191'); 
% test
% Gline(18,3) = 0.41;
%合并相同节点管道

% samepipe=[];
% for i=1:size(Gline,1)
%     for j=(i+1):size(Gline,1)
%         if (Gline(i,1)==Gline(j,1))&&(Gline(i,2)==Gline(j,2))
%             Gline(i,3:5)=Gline(i,3:5)+Gline(j,3:5);
%             samepipe=[samepipe;j];
%         end
%     end
% end
% Gline(samepipe,:)=[]; 
mpc.Gline=Gline;

%% GAS SOURCES
% update the gas load and gas source
%1: located bus %2:Pg %3:Pgmin %4:Pgmax(Mm3/day)
mpc.Gsou= readmatrix('mpc.xlsx','Sheet','Gsou','Range','A2:D9');
% divide into several small gas sources
% proportion = [5,4,2,1,1,1];
% newGsou = [];
% for i = 1:6
%     addGsou = repmat([Gsou(i,1),Gsou(i,2:4)/proportion(i)],[proportion(i),1]);
%     newGsou = [newGsou; addGsou];
% end
% mpc.Gsou=newGsou;
% mpc.gasCompositionForGasSource = [
%     91.92 	4.39 	0.53 	0.09 	0.00 	0.76 	2.31 
%     86.28 	7.01 	1.21 	0.27 	0.00 	0.50 	4.73 
%     91.66 	3.88 	0.46 	0.13 	0.00 	1.54 	2.33 
%     92.19 	4.32 	0.43 	0.03 	0.00 	0.76 	2.28 
%     97.71 	0.63 	0.07 	0.02 	0.00 	1.12 	0.45 
%     94.00 	0.00 	0.00 	0.00 	0.50 	2.50 	2.50  
% ] / 100;
mpc.gasCompositionForGasSource = [
    100 0
    100 0
    100 0
    100 0
    100 0
    100 0
    100 0
    100 0
] / 100;
%% gas-electricity interface %用到GEcon的时候小心，第一列不一定按顺序来
%1st col: gas bus index.  %2nd col: elec bus index
% 用于找已知电力节点的GFU的所在天然气节点
GEcon=[
    148	5
    159	13
    165	16
    139	28
    132	39
    122	45
    21	96
    77	142
];
mpc.GEcon=GEcon;
%% ptg
% gas bus, electricity bus, effciency, min cap, max cap
mpc.ptg=[
    5	118	0.95 200	1.2	3
    12	104	0.95 200	1.2	3
    144	26	0.95 200	1.2	3
    32	102	0.95 200	1.2	3
    59	148	0.95 200	1.2	3
    68	143	0.95 200	1.2	3
    48	171	0.95 200	1.2	3
    46	158	0.95 200	1.2	3
];
%% gas price($/Mm^3)
mpc.Gcost=[
    0.116
    0.118
    0.12
    0.12
    0.12
    0.125
    0.118
    0.125
 ];

mpc.LCecost=[%NOK挪威克朗/kwh
    0 1/60 1 4 24 %第一行是分段线性函数的时间节点,第二个单位是kw，后面三个单位是kwh
    0 5.6 14.4 10.8 8.8 % Large industry
    0 16.6 70.5 57.1 36.1 % Industry 
    0 18.7 99.6 97.1 56.1 % Commercial
    0 4.2 16.2 11.8 8.6 % Agriculture
    0 0 8.6 8.7 7.4 ];% Residential    
% 转换物理量单位为MWh，货币单位换成成美元
mpc.LCecost(2:end,2) = mpc.LCecost(2:end,2) * 60;
mpc.LCecost(2:end,:) = mpc.LCecost(2:end,:) * 0.1272 * 1000;%阿里汇率20180228

% consumer sectors portions
%bus %large industry %industrial % commercial %agriculture %residential
mpc.consumerSectorPortion = [
    0 0.175  0.2775 0.185  0      0.3625;
    0 0.6529 0.0359 0.0553 0.0218 0.2341;
    0 0.4075 0      0.1175 0      0.4750;
    0 0.2775 0.0925 0.185  0      0.445; 
    0 0      0.1525 0.085  0.37   0.3925;%5
    0 0.175  0.2775 0.185  0      0.3625;
    0 0.6529 0.0359 0.0553 0.0218 0.2341;
    0 0.4075 0      0.1175 0      0.4750;
    0 0.2775 0.0925 0.185  0      0.445; 
    0 0      0.1525 0.085  0.37   0.3925;%10
    0 0.175  0.2775 0.185  0      0.3625;
    0 0.6529 0.0359 0.0553 0.0218 0.2341;
    0 0.4075 0      0.1175 0      0.4750;
    0 0.2775 0.0925 0.185  0      0.445; 
    0 0      0.1525 0.085  0.37   0.3925;%15
    0 0.175  0.2775 0.185  0      0.3625;
    0 0.6529 0.0359 0.0553 0.0218 0.2341;
];

%% ----------gas trasient----------------
% 3 diameter (mm) 4 length (km)
GlineRaw = [Gline(:,1),Gline(:,2),Gline(:,6),Gline(:,7)];%$$$$$$
% measuring unit convert
GlineRaw(:,3) = GlineRaw(:,3) / 1000;
GlineRaw(:,4) = GlineRaw(:,4) * 1000;
%合并相同节点管道
% GlineRaw(samepipe,:)=[];
% calculate F
[para] = initializeParameters2();
[~,~,~,~,~,B,~,~,rhon] = unpackPara2(para);
D = GlineRaw(:,3); A = pi*(D/2).^2;
F = sqrt( 4*rhon^2*B^2.*GlineRaw(:,4).*Gline(:,3).^2*(10^6/86400)^2 ./ (D.*A.^2*10^10) );
% F = [19.2846524568081,19.2823964261944,22.9256112527948,22.1074586954129,22.1070928804400,22.0662780083436,22.9256536095011,20.5541972779392,20.5366958945471,20.5294097684344,22.9205329384028,22.9219360363933,22.9333207807464,22.9339748683452,22.9372529249245,21.2722611505256,20.7557112813557,20.6517973350085,20.8138804740731]';
gtd.Gline = [GlineRaw,F];
%% EH location
% indexed by gas bus
mpc.EHlocation = [3 6 7 10 12 15 16 19;
                  8 20 10 5 4 15 16 19]';

