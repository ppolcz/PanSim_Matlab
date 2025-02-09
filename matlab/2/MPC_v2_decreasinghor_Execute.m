
Tp = 14;

N = 6*7*4;
Nr_Periods = N / Tp;

t_sim = 0:N;
d_sim = C.Start_Date + t_sim;

%________________________________________________________________
%% Random reference

% 0, 1, 3, 6, 14, 1996
Rng_Int = round(rand*10000);
% Rng_Int = 1996;
% Rng_Int = 0;
% Rng_Int = 3466;

Name = "Ketpupu_Teve";
Rng_Int = 1647; % <---- 5 + 20 db szep eredmeny 2024.02.14. (február 14, szerda), 11:38

% Name = "Erdekes_Teve";
% Rng_Int = 7597; % <---- 3db szep eredmeny 2024.02.14. (február 14, szerda), 11:38

Iref = generate_path(Rng_Int,N);

save("Iref.mat","Iref","Tp","N","Name")
for i=1:10; MPC_v2_decreasinghor_Load; end

%________________________________________________________________
%% Constant reference

Iref = t_sim'*0 + 500;

Name = "C590";
save("Iref.mat","Iref","Tp","N","Name")
for i=1:20; MPC_v2_decreasinghor_Load; end

%________________________________________________________________
%% Increasing reference

Iref = t_sim(:) ./ N * 1500;

Name = "Lin1500";
save("Iref.mat","Iref","Tp","N","Name")
for i=1:20; MPC_v2_decreasinghor_Load; end

%________________________________________________________________
%% Sigmoid reference

h = [1 2 1 2 1]*N/7;
u = @(i,a) zeros(1,h(i))+a;
S = @(i,a,b) Epid_Par.Sigmoid(a,b,h(i));
Iref = [ ...
    u(1,0) ...
    S(2,0,1) ...
    u(3,1) ...
    S(4,1,0) ...
    u(5,0), 0 ...
    ]'*800;

Name = "Sigmoid";
save("Iref.mat","Iref","Tp","N","Name")
for i=1:20; MPC_v2_decreasinghor_Load; end

%%% ------------------------------------------------------------


function Iref = generate_path(Rng_Int,N)

    t_sim = 0:N;

    rng(Rng_Int)
    while true

        Possible_Tks = divisors(N);
        Possible_Tks(Possible_Tks <= 10) = [];
        Possible_Tks(Possible_Tks > 70) = [];
        Tk = Possible_Tks( floor(( rand * (numel(Possible_Tks)-eps) ))+1 );

        Max_Inf = C.Np / 30;

        hyp = {};
        hyp.X = t_sim( sort(randperm(numel(t_sim),N/Tk)) )';
        hyp.y = rand(size(hyp.X)) * Max_Inf;
        hyp.sf = 36;
        hyp.sn = 25;
        hyp.ell = Tk;

        hpy = GP_eval(hyp);
        Iref = GP_eval(hyp,t_sim);

        wFnSup = 2.5;
        x = linspace(-wFnSup,wFnSup,numel(t_sim));
        w = normpdf(x,0,1)';
        w = w - w(1);
        [mw,idx] = max(w);
        w = w ./ mw;
        w(idx:end) = 1;

        Iref = Iref .* w;
        if all(Iref >= 0)
            break
        end
    end

end