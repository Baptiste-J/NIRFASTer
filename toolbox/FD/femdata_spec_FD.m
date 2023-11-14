function [data, varargout] = femdata_spec_FD(mesh, frequency, varargin)
% FEMDATA_SPEC_FD Calculates data (phase and amplitude) for a given
%   spectral mesh at a given frequency (Hz). Outputs phase and amplitude in
%   the structure DATA.
% 
% SYNTAX:
%  [DATA] = FEMDATA_SPEC_FD(MESH, FREQUENCY)
%  [DATA] = FEMDATA_SPEC_FD(MESH, FREQUENCY, SOLVER)
%  [DATA] = FEMDATA_SPEC_FD(MESH, FREQUENCY, OPTIONS)
%  [DATA] = FEMDATA_SPEC_FD(MESH, FREQUENCY, SOLVER, OPTIONS)
%  [DATA] = FEMDATA_SPEC_FD(MESH, FREQUENCY, SOLVER, OPTIONS, ISFIELD)
%  [DATA,INFO] = FEMDATA_SPEC_FD(___)
% 
% 
% [DATA] = FEMDATA_SPEC_FD(MESH, FREQUENCY) MESH is NIRFAST mesh
%   structure, FREQUENCY is source frequency (>=0) in Hz. Data are
%   calculated at all wavelength specified in 'MESH.wv' and enabled in
%   'MESH.link' fields. A default solver is used. DATA structure has
%   following entries:
%    - DATA.PHI - N by M by W matrix of photon fluence rate at N nodes for M
%       sources at W wavelengths as enabled in 'MESH.link' field. Expressed
%       in mm^-2s^-1. 
%    - DATA.COMPLEX - P by W matrix of photon fluence rate for P
%       source-detectors pairs and W wavelengths as enabled in 'MESH.link'.
%       It has COMPLEX entries. Expressed in mm^-2s^-1. 
%    - DATA.LINK - copy of MESH.LINK showing how sources and detectors at
%       different wavelengths are linked together into pairs.
%    - DATA.AMPLITUDE - absolute value of the DATA.COMPLEX. Expressed in
%       mm^-2s^-1.
%    - DATA.PHASE - angle (polar coordinate) of DATA.COMPLEX. Expressed in
%       degrees.
%    - DATA.WV - copy of MESH wavelengths. Expressed in nm;
% 
% [DATA] = FEMDATA_SPEC_FD(MESH, FREQUENCY, SOLVER) User specified SOLVER
%   is used. Type 'help get_solver' for how to use solvers. Data are
%   calculated at all wavelength specified in 'MESH.wv' and enabled in
%   'MESH.link' fields.
% 
% [DATA] = FEMDATA_SPEC_FD(MESH, FREQUENCY, OPTIONS) Default solver is
%   used. See help of the 'get_solvers' function for how the default solver
%   is determined. Data are calculated at all wavelength specified in
%   'MESH.wv' and enabled in 'MESH.link' fields. OPTIONS is a structure
%   that allows to control solvers parameters. The OPTIONS structure can
%   have following optional entries:
%       - OPTIONS.no_of_iter (default 1000)
%         Maximum number of BiCGStab iterations.
%       - OPTIONS.tolerance (default 1e-8);
%         Absolute convergence tolerance (norm of solution error).
%       - OPTIONS.rel_tolerance (default 1e-8);
%         Relative convergence tolerance (norm of solution error related to
%         norm of error of first iteration).
%       - OPTIONS.divergence_tol (default 1e8);
%         Relative divergence tolerance (related to first iteration).
%       - OPTIONS.GPU (default -1);
%         Index of GPU requested to be used. By default (-1) the GPU of the
%         highest compute capability is used. Use the 'isCUDA' function to
%         get the installed GPUs info. The indexing is 0-based and the
%         indexing order is the same as in the list of GPUs returned by the
%         'isCUDA' function.
%   Entries within the structure are optional. The default OPTIONS
%   structure is returned by 'solver_options' function.
%
% [DATA] = FEMDATA_SPEC_FD(MESH, FREQUENCY, SOLVER, OPTIONS) User specified
%   SOLVER and its OPTIONS are used. See help of the 'get_solvers' function
%   for how to use solvers. The default OPTIONS structure is returned by
%   'solver_options' function. 
% 
% [DATA] = FEMDATA_SPEC_FD(MESH, FREQUENCY, SOLVER, OPTIONS, ISFIELD)
%   ISFIELD is logical t/f or numericla 0/1 to indicate if the 'DATA.PHI'
%   field should be returned. Default true (1).
% 
% [DATA,INFO] = FEMDATA_SPEC_FD(___) Also returns solvers
%   information/statistic in the INFO structure with following possible
%   entries:
%    - INFO.convergence_iterations (m by n matrix)
%      Number of iterations to converge to the tolerances for m sources as
%      enabled in 'MESH.link' and n wavelengths as specified in 'MESH.wv'.
%    - INFO.convergence_tolerances (m by n matrix)
%      Exact absolute tolerance at convergence for m sources as enabled in
%      'MESH.link' and n wavelengths as specified in 'MESH.wv'.
%    - INFO.isConverged (m by n matrix)
%      Logical flag if solution converged to tolerances for m sources as
%      enabled in 'MESH.link' and n wavelengths as specified in 'MESH.wv'.
%    - INFO.isConvergedToAbsTol (m by n matrix)
%      Logical flag if solution converged to the absolute tolerance for
%      m sources as enabled in 'MESH.link' and n wavelengths as specified
%      in 'MESH.wv'.
%    - INFO.convergence_iterations_limit
%      Maximum number of convergence iterations allowed.
%    - INFO.convergence_tolerance_limit
%      Absolute convergence tolerance requested.
%    - INFO.convergence_relative_tolerance_limit
%      Relative convergence tolerance (related to first iteration)
%      requested. 
%    - INFO.divergence_tolerance_limit
%      Maximum relative divergence tolerance (related to first
%      iteration) allowed. 
%    - INFO.status (m by n matrix)
%      Convergence flag (from 0 to 4) as returned by MATLAB 'bicgstab'. For
%      all m sources as enabled in 'MESH.link' and n wavelengths as
%      specified in 'MESH.wv'.. '0' means success. 
%   INFO is empty if the '\' solver is used.
% 
% WARNING
%   For large source-detector separations (>8cm).
%   Iterative solvers are set to use the follwoing absolute tolerance
%   'OPTIONS.tolerance=1e-8'. The absolute tlerance can be seen as a
%   maximum difference between iterative method result and direct solver
%   (MATLAB backslash '\'). 
%   As a rule of thumb, one order of the abosolute tolerance corresponds to
%   1cm of source-detector distance on a tissue. As such, the 1e-8 should
%   provide accurate results at least for 8cm source-detector distance.
%   Decrease the tolerance acordingly if you want to calculate data at
%   source-detector distance >8cm. However, the decreased tolerance
%   increases the execution time.
% 
% GUIDELINE
%   Please use the 'MESH.link' field to turn on/off wavelength at sources.
%   This field has following row entries:
%    #sour #det 0/1 0/1 ... 0/1
%   #sour - source label as in 'MESH.source.num', #det - detector label as
%   in 'MESH.meas.num', 0/1 this pair is off (0) or on (1), column position
%   of the 0/1 entries correspond to wavelengths as specified in 'MESH.wv'.
%   As such, if you want to disable a 2nd and 5th wavelengths at sources
%   labeled 13 and 16, please change the 'MESH.link' as follows:
%     sources2disable = [13 16];
%     wavelengths2disable = [2 5];
%     mask_sources = sum(mesh.link(:,1)==sources2disable,2) > 0;
%     mesh.link(mask_sources,wavelengths2disable+2) = 0;
%
% See also GET_SOLVER, FEMDATA_STND_FD, GET_FIELD_FD_CPU, GET_FIELD_FD_CUDA,
%          GEN_MASS_MATRIX_FD_CPU, GEN_MASS_MATRIX_FD_CUDA, GEN_SOURCES,
%          CALC_MUA_MUS.
% 
%   Part of NIRFAST package.
%   S. Wojtkiewicz and H. Dehghani 2018

%% check in/out

narginchk(2,5);
nargoutchk(0,2);

%% get optional inputs, handle variable input

% is the field at mesh nodes should be returned 
isField = true;

% default
solver = get_solver;
OPTIONS = solver_options;

if ~isempty(varargin)
    if length(varargin) == 1
        if ischar(varargin{1}) || isstring(varargin{1})
            % user specified, sanity check
            solver = get_solver(varargin{1});
        elseif isstruct(varargin{1})
            OPTIONS = varargin{1};
        else
            error('Bad 3rd argument value. Text or structure expected. Please see help for details on how to use this function.')
        end
    elseif length(varargin) == 2
        if ischar(varargin{1}) || isstring(varargin{1})
            % user specified, sanity check
            solver = get_solver(varargin{1});
        else
            error('Bad 3rd argument value. Text expected. Please see help for details on how to use this function.')
        end
        
        if isstruct(varargin{2})
            OPTIONS = varargin{2};
        else
            error('Bad 4th argument value. Structure expected. Please see help for details on how to use this function.')
        end
    elseif length(varargin) == 3
        if ischar(varargin{1}) || isstring(varargin{1})
            % user specified, sanity check
            solver = get_solver(varargin{1});
        else
            error('Bad 3rd argument value. Text expected. Please see help for details on how to use this function.')
        end
        if isstruct(varargin{2})
            OPTIONS = varargin{2};
        else
            error('Bad 4th argument value. Structure expected. Please see help for details on how to use this function.')
        end
        if numel(varargin{3}) == 1
            isField = logical(varargin{3});
        else
            error('Bad 5th argument value. Scalar expected. Please see help for details on how to use this function.')
        end
    else
        error('Bad arguments. Please see the help for details on how to use this function.')
    end
end

%% check solver

solver = get_solver(solver);

%% If not a workspace variable, load mesh
if ~isstruct(mesh)
    mesh = load_mesh(mesh);
end

% check for spectral mesh and wavelengths field
if ~strcmp(mesh.type,'spec')
    warning(['Mesh type is ''' mesh.type '''. ''spec'' expected. This might give unexpected results.'])
end

if ~isfield(mesh,'wv')
    error('The mesh is missing ''wv'' field specifying wavelengths.');
end

%% Now calculate sources vector for those active in mesh.link

% --- EDIT Baptiste (08/11/2023)
% Moving all of the edit inside the loop because when there are 0s in the
% mesh.link matrix the qvec matrix is empty
qvec = gen_sources(mesh);

%% Catch zero frequency (CW) here
if frequency == 0
    qvec = real(qvec);
end
% --- END EDIT (08/11/2023)

%% LOOP THROUGH WAVELENGTHS

% check if a wavelength is turned off for all sources.
mask_wv_off = sum(mesh.link(:,3:end),1) == 0;

for ind_wv = 1:length(mesh.wv)
    % calculate only if wavelength requested.
    if ~mask_wv_off(ind_wv)
        
        % make a copy of spectral link
        link_copy = mesh.link;
        % put a single wavelength link into the mesh
        mesh.link = mesh.link(:,[1 2 ind_wv+2]);
        
        % get optical properties at nodes using spectra
        [mesh.mua, mesh.mus, mesh.kappa] = calc_mua_mus(mesh, mesh.wv(ind_wv));
        
        % ---- Edit by Baptiste Jayet (20/07/2020)
        % Addition of a constant mua region regardless of wavelength
        if isfield(mesh,'CONSTmua')
            if ~isempty(mesh.CONSTmua.number)
                fprintf(1,'Changing mua for region number: %d\n',mesh.CONSTmua.number)
                ind = find(mesh.region == mesh.CONSTmua.number);
                mesh.mua(ind) = mesh.CONSTmua.value;
                mesh.kappa = 1./(3*(mesh.mus+mesh.mua));
            end
        end
        % ---- End of Baptiste edit

        % ---- Edit by Baptiste Jayet (20/02/2023)
        % Addition of a melanin field
        if isfield(mesh,'mel')
            melNodes = find(mesh.mel);
            mua = calc_mua_mel(mesh.wv(ind_wv),mesh.fmel(melNodes));
            mesh.mua(melNodes) = mua;
        end
        % ---- End of Baptiste edit

        % Now calculate sources vector for those active in mesh.link

% % %         % --- EDIT Baptiste (08/11/2023)
% % %         % Moving all of the edit inside the loop because when there are 0s in the
% % %         % mesh.link matrix the qvec matrix is empty
% % %         qvec = gen_sources(mesh);
% % % 
% % %         % Catch zero frequency (CW) here
% % %         if frequency == 0
% % %             qvec = real(qvec);
% % %         end
% % %         % --- END EDIT (08/11/2023)
        
        % make FEM matrices
        if isCUDA
            if isfield(OPTIONS,'GPU')
                [i_index, j_index, value] = gen_mass_matrix_FD_CUDA(mesh,frequency,OPTIONS.GPU);
            else
                [i_index, j_index, value] = gen_mass_matrix_FD_CUDA(mesh,frequency);
            end
        else
            [i_index, j_index, value] = gen_mass_matrix_FD_CPU(mesh,frequency);
        end

        % get photon fluence rate
        % if GPU in use
        if strcmp(solver,solver_name_GPU)
            % check if we need to return the info structureas well
            if nargout == 2
                [phi, varargout{1}] = get_field_FD_CUDA(i_index, j_index, value, qvec, OPTIONS);
            else
                phi = get_field_FD_CUDA(i_index, j_index, value, qvec, OPTIONS);
            end
        % if no GPU in use, use CPU
        elseif strcmp(solver,solver_name_CPU)
            if nargout == 2
                [phi, varargout{1}] = get_field_FD_CPU(i_index, j_index, value, qvec, OPTIONS);
            else
                phi = get_field_FD_CPU(i_index, j_index, value, qvec, OPTIONS);
            end
        elseif strcmp(solver,solver_name_matlab_iterative)
            if nargout == 2
                [phi, varargout{1}] = get_field_FD_bicgstab_matlab(i_index, j_index, value, qvec, OPTIONS);
            else
                phi = get_field_FD_bicgstab_matlab(i_index, j_index, value, qvec, OPTIONS);
            end
        else
            % use MATLAB backslash
            % +1 as the i_index and j_index are zero-based and MATLAB uses 1-based indexing
            phi = full(sparse(i_index+1, j_index+1, value)\qvec);
            if nargout == 2
                varargout{1} = [];
            end
        end

        % return photon fluence rate if requested
        if isField
            data.phi(:,:,ind_wv) = phi;
        end
        % Calculate boundary data
        [data.complex(:,ind_wv)] = get_boundary_data(mesh, phi);
        
        % put back the spectral link into the mesh
        mesh.link = link_copy;
    else
        % set NaN if wavelength NOT requested
        if isField
            data.phi(:,:,ind_wv) = NaN(size(qvec));
        end
        data.complex(:,ind_wv) = NaN(size(mesh.link,1), 1);
    end

end
% Format output data
data.amplitude = abs(data.complex);
data.phase = angle(data.complex);
% shift angles < 0
data.phase(data.phase<0) = data.phase(data.phase<0) + (2*pi);
% convert to deg
data.phase = data.phase*180/pi;
% copy link to data
data.link = mesh.link;
% copy wavelengths to data
data.wv = mesh.wv;

end
