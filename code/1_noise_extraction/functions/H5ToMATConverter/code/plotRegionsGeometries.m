% Estimated geometry
Heart_estimated.vertices = episode.geometries.heart.ventricles.shapeModel.holeyGeometry.vertices.visualVertices; 
Heart_estimated.faces = episode.geometries.heart.ventricles.shapeModel.holeyGeometry.faces; 
faceTypes_estimated = episode.geometries.heart.ventricles.shapeModel.regions.faceTypes.holeyGeometry; 

nodeTypes_estimated = labels_faces2vertices(Heart_estimated.faces, faceTypes_estimated);

%%
regioni = 10; 
region.vertices = Heart_estimated.vertices(find(nodeTypes_estimated == regioni),:);
region.faces = Heart_estimated.faces(find(faceTypes_estimated == regioni),:);

visualizeMeshData(Heart_estimated); cameramenu; camlight headlight; hold on 
scatter3(region.vertices(:,1), region.vertices(:,2), region.vertices(:,3), 'oy')
% visualizeMeshData(region, [1 1 0], 'ax', gca)

fig_geom = plot_geometry_with_regions(Heart_estimated.vertices, Heart_estimated.faces, faceTypes_estimated, episode.geometries.heart.ventricles.shapeModel.regions.descriptions);
axis off; cameramenu; camlight headlight
%%

% Personalized geometry
Heart_personalized.vertices = geometry_personalized.ventricles.Maingeometry.Vertices; 
Heart_personalized.faces = geometry_personalized.ventricles.Maingeometry.Triangles; 
faceTypes_personalized = geometry_personalized.ventricles.Maingeometry.faceTypes+1; 

nodeTypes_personalized = geometry_personalized.ventricles.Maingeometry.nodeTypes+1;

%%
regioni = 20; 
region.vertices = Heart_personalized.vertices(find(nodeTypes_personalized == regioni),:);
region.faces = Heart_personalized.faces(find(faceTypes_personalized == regioni),:);

visualizeMeshData(Heart_personalized); cameramenu; camlight headlight; hold on 
scatter3(region.vertices(:,1), region.vertices(:,2), region.vertices(:,3), 'oy')

fig_geom = plot_geometry_with_regions(Heart_personalized.vertices, Heart_personalized.faces, faceTypes_personalized, geometry_personalized.ventricles.Maingeometry.labels); %  labelsStandardized
axis off; cameramenu; camlight headlight