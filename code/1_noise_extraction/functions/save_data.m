function save_data(dir, var)
%save_data: saves the variable into a .mat file in the indicated folder.
%
%Inputs:
% - dir: directory where the .mat file will be saved.
% - var: variable to be saved.
%
%Outputs:
% None. The function saves the variable into a .mat file.
%
%Last edited: 11/04/2025, Sabrina Strazzeri (sstrmui@itaca.upv.es)
%-------------------------------------------------------------------------

% Saves variable into a .mat file in the  indicated folder.
cd(dir)
var = var';
name = inputname(2);
save([name, '.mat'], "var");
disp(string(name) + ' has been saved.')

end