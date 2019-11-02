function [C] = LEDL_SRC_ADMM_test(ts_Y,B,sumY,par)
% 输入 ts_Y,B,K,alpha
% ts_Y是测试集，大小为D*N；B是训出来的字典，大小为D*K；alpha是稀疏系数；
% X是训练集,大小为 D*N；Y是标签,大小为 label*N；K是字典大小；alpha是稀疏系数；lambda是嵌入标签的系数
% 输出 C
% C,Z为稀疏矩阵，C=Z,大小为 K*N；
K                = par.method.param.K;
alpha_test       = par.method.param.alpha_test;
rho_test         = par.method.param.rho_test;
gd_test        = par.method.param.gd_test; %梯度上升步长
min_gd_test     = par.method.param.min_gd_test;
maxiter          = par.method.maxiter;

kernel_tstr = B' * ts_Y;
kernel_train= B' * B;

% Get dimensions of B
c = size(kernel_tstr,2);
r = size(kernel_train,2); 

delta = zeros(r,c); % Initialize Lagragian to be nothing (seems to work well)
I = speye(r); % Set the sparse identity matrix
Z = zeros(r,c); % Initialize Z

% Set the fast soft thresholding function
fast_sthresh = @(x,th) sign(x).*max(abs(x) - th,0);

% Set the norm functions
norm2 = @(x) x(:)'*x(:);
norm1 = @(x) sum(abs(x(:))); 
    
cost = [];
fold = 9999999;
fnew = 999999;
n = 0;
% for n = 1:maxIter
% while (fold-fnew)/fold>1*1e-8 && n<maxIter
% maxiter = 10000;
while  n<maxiter
    
    n = n+1;
    % Solve sub-problem to solve B
    C = (kernel_train + rho_test*I)\(kernel_tstr + rho_test*Z - delta); 

    % Solve sub-problem to solve C
    Z = fast_sthresh(C + delta/rho_test, alpha_test/rho_test); 

    % Update the Lagrangian
    delta = (1-gd_test)*delta + gd_test*(C - Z);
    gd_test = max(min_gd_test, gd_test*0.99);
    
    % get the current cost
%     cost(n) = 0.5*norm2(X - A*B) + gamma*norm1(B);
    fold = fnew;
    cost(n) = 0.5*(sumY+trace(C'*kernel_train*C)-2*trace(kernel_tstr*C'))+ alpha_test*norm1(C);
    fnew = cost(n);
%     fprintf('Iter = %.2f, cost = %.8f\n',n,cost(n));
end
return;