function plotmesh(mesh, isPlotFiducials)
% PLOTMESH Allows fast and easy viewing of meshes in NIRFAST format.
% 
% SYNTAX:
%   PLOTMESH(MESH)
%   PLOTMESH(MESH, ISPLOTFIDUCIALS)
% 
%   PLOTMESH(MESH) MESH is NIRFAST mesh structure.
%   PLOTMESH(MESH, ISPLOTFIDUCIALS) MESH is the NIRFAST mesh structure.
%    ISPLOTFIDUCIALS is logical true or false if the source/detectors will
%    show.
%
%   Part of NIRFAST package.

%% load mesh
if ischar(mesh)== 1
    mesh = load_mesh(mesh);
end

%% plot sources/detectors

if nargin == 1
    isPlotFiducials = false;
end

if isPlotFiducials
    
    plotmesh_fiducials(mesh);
    
end


%% plot optical properties

if mesh.dimension == 3
    disp(' ');
    disp('NOTICE: 3-D meshes are now only viewable using the NIRFASTSlicer or ParaView interfaces.')
    disp('TO VIEW: Make sure the 3-D mesh is saved and has an associated .vtk file.')
    disp('         Drag and drop the mesh''s .vtk file into NIRFASTSlicer (as a Model).')
    disp('         Use the Models module to adjust viewing parameters.');
    
    TR = triangulation(mesh.elements, mesh.nodes(:,1:mesh.dimension));
    [F,P] = freeBoundary(TR);
    
    figure('Name',mesh.name)
    trisurf(F,P(:,1),P(:,2),P(:,3), 'FaceColor','cyan','FaceAlpha',0.8);
    title('mesh surface')
    xlabel('x position (mm)');
    ylabel('y position (mm)');
    zlabel('z position (mm)');

else
    figure('Name',mesh.name)
    set(gca,'FontSize',28)

    % STANDARD
    if strcmp(mesh.type,'stnd') == 1
        subplot(1,2,1)
        plotim(mesh,mesh.mua)
        title('\mu_a','FontSize',20);
        colorbar('horiz');

        subplot(1,2,2);
        plotim(mesh,mesh.mus);
        title('\mu_s''','FontSize',20);
        colorbar('horiz');

    % FLUORESCENCE
    elseif strcmp(mesh.type,'fluor') == 1
        
        subplot(3,2,1);
        plotim(mesh,mesh.muax);
        title('\mu_{ax}','FontSize',10);
        colorbar;

        subplot(3,2,2);
        plotim(mesh,mesh.musx);
        title('\mu_{sx}''','FontSize',10);
        colorbar;

        subplot(3,2,3);
        plotim(mesh,mesh.muam);
        title('\mu_{am}','FontSize',10);
        colorbar;

        subplot(3,2,4);
        plotim(mesh,mesh.musm);
        title('\mu_{sm}''','FontSize',10);
        colorbar;

        subplot(3,2,5);
        if isfield(mesh,'etamuaf') == 1
          plotim(mesh,mesh.etamuaf);
        else
          plotim(mesh,mesh.muaf.*mesh.eta);
        end
        title('\eta\mu_{fl}','FontSize',10);
        colorbar;

        subplot(3,2,6);
        plotim(mesh,mesh.tau);
        title('\tau','FontSize',10);
        colorbar;

    % SPECTRAL
    elseif strcmp(mesh.type,'spec') == 1
        [nc,~] = size(mesh.chromscattlist);

        if isfield(mesh,'etamuaf')
            n = ceil((nc-2)/2)+2;
        else
            n = ceil((nc-2)/2)+1;
        end
        k = 0;
        for i = 1 : nc-2
            k = k + 1;
            subplot(n,2,k);
            plotim(mesh,mesh.conc(:,i));
            t = char(mesh.chromscattlist(i,1));
            title(t,'FontSize',10);
            colorbar;
        end
        subplot(n,2,k+1);
        plotim(mesh,mesh.sa);
        title('Scatter Amplitude','FontSize',10);
        colorbar;
        
        subplot(n,2,k+2);
        plotim(mesh,mesh.sp);
        title('Scatter Power','FontSize',10);
        colorbar;
        
        if isfield(mesh,'etamuaf')
            subplot(n,2,k+3);
            plotim(mesh,mesh.etamuaf);
            title('etamuaf','FontSize',10);
            colorbar;
        end
    else
        warning('Mesh type not supported.');
    end
end

end


%% plot image function
function plotim(mesh, val)
    if mesh.dimension == 3
        trisurf(mesh.elements,...
            mesh.nodes(:,1),...
            mesh.nodes(:,2),...
            mesh.nodes(:,3),...
            val,'FaceAlpha',0.5);
    else
        trisurf(mesh.elements,...
            mesh.nodes(:,1),...
            mesh.nodes(:,2),...
            val);
    end
    shading interp;
    view(2);
    axis equal; 
    axis off;
    colormap hot;
end

%% set font function
function setfont(s)

    title([],'fontsize',s);
    xlabel([],'fontsize',s);
    xlabel([],'fontsize',s);
    set(gca,'fontsize',s);
        
end
