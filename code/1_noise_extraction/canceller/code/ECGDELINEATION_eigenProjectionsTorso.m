function [eigenProjections] = ECGDELINEATION_eigenProjectionsTorso(Torso) 
% Eigenvectors of toros Geometry
% Inputs:
% Torso geometry: struct with vertices and faces
% Outputs:
% eigenVectors
% Creation: Rubén Molero (ruben.molero@corifycare.com) Implementation from
% Ismael Hernández code
    [Lc,~] = GEOMETRY_tuftedLaplacian_mex(Torso.vertices,Torso.faces);  
                
    k = 5;
    [V, D] = eigs(Lc, [], k, 'sm'); 
    
    eigen=abs(diag(D));
    if eigen(1) < eigen(end)
    
        Psi=V(:,1:k);
    else
        % there is a chance eigenvalues are sorted in the reverse order.
        Psi=V(:,end-k+1:end);
    end
    eigenProjections = ((Psi'*Psi)\Psi');
end