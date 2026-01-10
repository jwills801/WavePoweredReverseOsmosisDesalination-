function [F, Q_discrete, B_discrete] = van_loan_discretization(A_c, Q_c, B_c, dt)
% VAN_LOAN_DISCRETIZATION Discretize continuous-time system using Van Loan method
%
% Inputs:
%   A_c       - Continuous-time state matrix (n x n)
%   Q_c       - Continuous-time process noise covariance (n x n)
%   B_c       - Continuous-time input matrix (n x m) [optional]
%   dt        - Time step
%
% Outputs:
%   F         - Discrete-time state transition matrix (n x n)
%   Q_discrete - Discrete-time process noise covariance (n x n)
%   B_discrete - Discrete-time input matrix (n x m) [optional]
%
% Method: Uses Van Loan's approach with matrix exponential

n = size(A_c, 1);  % Number of states

% Van Loan method for F and Q_discrete
% Construct the augmented matrix M
M = [-A_c * dt,  Q_c * dt;
     zeros(n,n), A_c' * dt];

% Compute matrix exponential
exp_M = expm(M);

% Extract results
Phi_11 = exp_M(1:n, 1:n);
Phi_12 = exp_M(1:n, n+1:2*n);
Phi_22 = exp_M(n+1:2*n, n+1:2*n);

% Discrete-time matrices
F = Phi_22';
Q_discrete = F * Phi_12;

% Compute B_discrete if B_c is provided
if nargin >= 3 && ~isempty(B_c)
    % B_discrete = A_c^(-1) * (F - I) * B_c
    % More numerically stable computation:
    if rcond(A_c) > eps
        % A_c is invertible
        B_discrete = A_c \ (F - eye(n)) * B_c;
    else
        % A_c is singular, use series approximation
        B_discrete = B_c * dt;  % First-order approximation
        warning('A_c is singular, using first-order approximation for B_discrete');
    end
else
    B_discrete = [];
end

end