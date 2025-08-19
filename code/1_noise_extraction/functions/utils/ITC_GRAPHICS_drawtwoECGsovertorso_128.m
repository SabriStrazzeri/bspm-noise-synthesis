
function ITC_GRAPHICS_drawtwoECGsovertorso_128(ECG1,ECG2,elim)

% Draw 2 ECGs over the patient body - 128 electrodes
%
% Inputs 
% - ECG1: 128xn (n = instants times)
% - ECG2: 128xn (n = instants times)
% - elim: leads that you do not want to plot (leadstatus==0)
% - CC: correlation coefficient between them
%
% Created by Clara Herrero Martín 05/05/2023
% Modified by Inés Llorente 08/05/2023
% -----------------------------------------------------------------------

% Generate grid
Y = zeros(1,128);
Y([88 99 107 108 111 60 52 50 61 55 32 22 25 45 116 65 66 70]) = 1;
Y([95 91 86 79 100 62 16 2 15 12 18 21 24 38 115 119 42 71]) = 2;
Y([96 93 68 85 110 53 3 14 4 10 31 29 23 47 124 121 78 75]) = 3;
Y([94 83 69 84 102 63 13 5 28 9 17 27 48 44 126 118 80 72]) = 4;
Y([81 82 74 92 97 54 11 30 6 7 19 20 36 35 117 125 77 76]) = 5;
Y([90 101 98 58 49 56 26 43 8 128 127 120]) = 6;
Y([109 103 73 64 41 51 46 37 123 105 113 114]) = 7;
Y([106 87 40 59 57 39 34 33 122 104 112 67]) = 8;
Y([89 1]) = 9;

X = zeros(1,128);
X([88 95 96 94 81]) = 1;
X([99 91 93 83 82]) = 2;
X([107 86 68 69 74 90 109 106 89]) = 3;
X([108 79 85 84 92 101 103 87]) = 4;
X([111 100 110 102 97 98 73 40]) = 5;
X([60 62 53 63 54 58 64 59]) = 6;
X([52 16 3 13 11 49 41 57]) = 7;
X([50 2 14 5 30 56 51 39 1]) = 8;
X([61 15 4 28 6]) = 9;
X([55 12 10 9 7]) = 10;
X([32 18 31 17 19]) = 12;
X([22 21 29 27 20 26 46 34]) = 13;
X([25 24 23 48 36 43 37 33]) = 14;
X([45 38 47 44 35 8 123 122]) = 15;
X([116 115 124 126 117 128 105 104]) = 16;
X([65 119 121 118 125 127 113 112]) = 17;
X([66 42 78 80 77 120 114 67]) = 18;
X([70 71 75 72 76]) = 19;

% Plot
[nL,nS] = size(ECG1);
ECGnorm1 = ECG1;
ECGnorm2 = ECG2;

figure;
for i=1:128

    if ismember(i,elim) == 0

        ECGp1 = Y(i)+(ECGnorm1(i,:)).*0.5;
        ECGp2 = Y(i)+(ECGnorm2(i,:)).*0.5;
        l = linspace(X(i)-0.4,X(i)+0.4,nS);
                
        hold on    
        plot(l,ECGp1,'b','linestyle','-','LineWidth',1.5)
        plot(l,ECGp2,'r','linestyle','-','LineWidth',1.5)
            
    end

    l_all(i,:)= l;
    
end

% Front
min_front = min(l_all(l_all<6));
max_front = max(l_all(l_all<7));
medium_front = round(min_front+ max_front)/2;
text(medium_front+1,9.75,'Front','FontSize',15,'FontWeight','bold')

% Back
min_back = min(l_all(l_all>7));
max_back = max(l_all(l_all>7));
medium_back = round(min_back+ max_back)/2;
text(medium_back+2,9.75,'Back','FontSize',15,'FontWeight','bold')

end
