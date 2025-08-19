function [lap_tufted,mass_tufted] = mesh_tufted_laplacian_free(vfinal,ffinal)

% get the path
completePath = which('tufted-idt.exe');
appPath = erase(completePath, 'tufted-idt.exe');
   
 
%%write the obj file
if (size(vfinal,1) == 3) || (size(vfinal,2) == 3)
    if nargin == 2
        write_obj('processing_file.obj',vfinal,ffinal);
    else
        write_obj('processing_file.obj',vfinal);
    end
else
    write_obj_2Dvertices('processing_file.obj',vfinal);
end

%%call systemd with the command
 
cmd = appPath + "tufted-idt processing_file.obj --writeLaplacian --writeMass";
status = system(cmd);

%%parse the results
%%tufted laplacian
load tufted_laplacian.spmat;        
laplacian = spconvert(tufted_laplacian);    

load tufted_lumped_mass.spmat;
mass_tufted = spconvert(tufted_lumped_mass);

lap_tufted = laplacian;

delete('tufted_laplacian.spmat')
delete('tufted_lumped_mass.spmat')
delete('processing_file.obj')