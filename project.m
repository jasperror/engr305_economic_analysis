clear; close all; clc
% Building Constants
BEAM.N = 120; % Number of glulam beams, []
BEAM.W = 0.28; % Weight per beam, tonne

n_a = 4;
n_t = 13;

gst = 0.05; % Goods and services tax
cit = 0.12; % Corporate income tax rate

function [NPV, net] = financial(n_a, n_t, BEAM, gst, cit, i_r_yearly, p_sold, p_pass, profit, contractor, handgrad, f_yearly)
    lfc = 115*BEAM.W; % Per-beam landfill cost
    f = (1+f_yearly)^(1/12); % Monthly inflation rate
    
    % Profits
    profit_scrap = 2000;
    mo_profit = [2; 5; 13]; % Beam sale month
    mo_scrap = [2; 5; 5]; % Scrap recovery month
    
    % Variable Costs
    
    cpb = [0; 60; 150]; % Per-beam cleaning/restoration fees
    smc = 2.3; % Per beam-month storage and insturance costs
    stc = 18; % Per beam transportation to storage costs
    
    cost.contractor = contractor;
    cost.handling = handgrad;
    cost.restoration = zeros(n_a, n_t); cost.restoration(1:3,1:3) = repmat(BEAM.N/3.*cpb,1,3); % Total cleaning/restoration fees
    cost.landfill = zeros(n_a, n_t); cost.landfill(1:3,1:4) = [
        0, lfc*(1-p_pass(1)-.05)*BEAM.N, 0, 0;
        0, lfc*(1-p_pass(2)-.05)/3*BEAM.N, lfc*(1-p_pass(2)-.05)/3*BEAM.N, lfc*(1-p_pass(2)-.05)/3*BEAM.N;
        0, lfc*(1-p_pass(3)-.05)/3*BEAM.N, lfc*(1-p_pass(3)-.05)/3*BEAM.N, lfc*(1-p_pass(3)-.05)/3*BEAM.N
    ]; % Landfill costs
    cost.security = [0, 8500, 0, 0; 0, 8500, 8500, 8500; 0, 8500, 8500, 8500]; % Site security fees
    cost.security(:,end+1:13) = 0; cost.contractor(:,end+1:13) = 0; cost.handling(:,end+1:13) = 0; cost.restoration(:,end+1:13) = 0; cost.landfill(:,end+1:13) = 0;
    cost.security(end+1,:) = 5000; cost.security(end,1) = 8000;
    cost.storage = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;
        0, BEAM.N*p_pass(2)*(stc+smc)/3, BEAM.N*p_pass(2)*(stc+smc)/3 + BEAM.N*p_pass(2)*(smc)/3, BEAM.N*p_pass(2)*(stc+smc)/3 + BEAM.N*p_pass(2)*(smc)*2/3, 0, 0, 0, 0, 0, 0, 0, 0, 0;
        0, BEAM.N*p_pass(3)*(stc+smc)/3, BEAM.N*p_pass(3)*(stc+smc)/3 + BEAM.N*p_pass(3)*(smc)/3, BEAM.N*p_pass(3)*(stc+smc)/3 + BEAM.N*p_pass(3)*(smc)*2/3, BEAM.N*p_pass(3)*smc, BEAM.N*p_pass(3)*smc, BEAM.N*p_pass(3)*smc, BEAM.N*p_pass(3)*smc, BEAM.N*p_pass(3)*smc, BEAM.N*p_pass(3)*smc, BEAM.N*p_pass(3)*smc, BEAM.N*p_pass(3)*smc, BEAM.N*p_pass(3)*smc;
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    ]; % Storage & insurance costs
    cost.permit = zeros(4,13); cost.permit(1:3,1) = 5000; % Initial permit cost
    cost.pong = zeros(4,13); cost.pong(1,2) = 500; cost.pong(2:3,2:4) = 500; % ongoing permit cost
    cost.admin = zeros(4,13); cost.admin(1, 2) = 2500; cost.admin(2:3,2:4) = 2500; % Administrative costs
    cost.market = zeros(4,13); cost.market(1:3,1) = [0; 1000; 3000];
    cost.asbestos = zeros(4,13); cost.asbestos(1:3,2) = 5000;
    cost.nd = zeros(4,13); cost.nd(4,1) = .89e6;
    cost.total_pe = cost.contractor +  cost.handling + cost.restoration + cost.landfill + cost.security + cost.storage + cost.permit + cost.pong + cost.admin + cost.market + cost.asbestos + cost.nd; % Pre-inflation, pre-tax costs
    
    revenue = zeros(n_a, n_t);
    
    for i = 1:n_a-1
        revenue(i,mo_profit(i)) = profit(i)*p_sold(i)*p_pass(i)*BEAM.N - lfc*(1-p_pass(i)-.05)*BEAM.N - lfc*p_pass(i)*(1-p_sold(i))*BEAM.N; % Beam sales - landfill costs for beams not recoverable - landfill costs for beams which arent sold
        revenue(i,mo_scrap(i)) = revenue(i,mo_scrap(i))+profit_scrap; % Scrap metal recovery
    end
    for t = 1:n_t
        cost.total(:,t) = cost.total_pe(:,t).*f^(t-1); % Costs in inflated dollars
        revenue(:,t) = revenue(:,t).*(1-cit).*f^(t-1); % Revenue in inflated dollars after tax
        cost.gst(:,t) = (cost.total_pe(:,t).*f^(t-1)).*gst; % Calculate JUST PST of PST subject expenses
    end
    cost.total = cost.total + cost.gst;
    net = cost.total-revenue;
    
    % Present Value
    i_r = (1+i_r_yearly)^(1/12);
    
    % Convert future costs to net present cost
    NPV = zeros(n_a,1);
    for i = 1:n_a
        CF = flip(net(i,:)); % Cash flows for this alternative
        for k = 1:length(CF)-1
            NPV(i) = ( NPV(i)+CF(k) )*i_r^-1;
        end
        NPV(i) = NPV(i)+CF(end); % No interest on cashflow of year zero
    end
end

%% Sensitivity

f_yearly = 0.025; % Inflation rate per year
i_r = 0.12; % Real yearly MARR
i_r_yearly_pretax = i_r+f_yearly+i_r*f_yearly; % Nominal (after inflation) yearly MARR
i_r_yearly = i_r_yearly_pretax*(1-cit); % After-tax nominal yearly MARR
p_pass = [.25; .85; .85]; % Change of beams passing inspection
p_sold = [.9; .75; .6]; % Chance of beams being sold for each option
profit = [1000*BEAM.W+50; 945; 1200]; % Per-beam profit
contractor = zeros(n_a,n_t); contractor(1:3,1:3) = [
    220000, 0, 0; 
    235000/3, 235000/3, 235000/3; 
    235000/3, 235000/3, 235000/3
]; % Contractor costs
hpb = [0; 250+120; 250+120]; % per-beam handling and grading
handling = zeros(n_a, n_t); handling(1:3,2:4) = repmat(BEAM.N*hpb/3, 1, 3); % Total beam handling fees

lower = 0.5;
upper = 1.5;
N = 11;

v.ir = linspace(lower*i_r_yearly, upper*i_r_yearly, N);
v.f = linspace(lower*f_yearly, upper*f_yearly, N);
upp = upper.*p_pass; upp(upp>1)=1;
ups = upper.*p_sold; ups(ups>1)=1;

for i = 1:3
    v.pp(i,:) = linspace(lower*p_pass(i), upp(i), N);
    v.ps(i,:) = linspace(lower*p_sold(i), ups(i), N);
    v.pr(i,:) = linspace(lower*profit(i), upper*profit(i), N);
end

for i = 1:4
    for j = 1:13
        v.co(i,j,:) = linspace(lower*contractor(i,j), upper*contractor(i,j), N);
        v.ha(i,j,:) = linspace(lower*handling(i,j), upper*handling(i,j), N);
    end
end
n_v = length(fieldnames(v));

NPV = zeros(n_a, N, 6);
[NPV(:,1,1), net] = financial(n_a, n_t, BEAM, gst, cit, i_r_yearly, p_sold, p_pass, profit, contractor, handling, f_yearly);
for i = 1:N
    NPV(:,i,2) = financial(n_a, n_t, BEAM, gst, cit, v.ir(i), p_sold, p_pass, profit, contractor, handling, f_yearly);
    NPV(:,i,3) = financial(n_a, n_t, BEAM, gst, cit, i_r_yearly, v.ps(:,i), p_pass, profit, contractor, handling, f_yearly);
    NPV(:,i,4) = financial(n_a, n_t, BEAM, gst, cit, i_r_yearly, p_sold, v.pp(:,i), profit, contractor, handling, f_yearly);
    NPV(:,i,5) = financial(n_a, n_t, BEAM, gst, cit, i_r_yearly, p_sold, p_pass, v.pr(:,i), contractor, handling, f_yearly);
    NPV(:,i,6) = financial(n_a, n_t, BEAM, gst, cit, i_r_yearly, p_sold, p_pass, profit, v.co(:,:,i), handling, f_yearly);
    NPV(:,i,7) = financial(n_a, n_t, BEAM, gst, cit, i_r_yearly, p_sold, p_pass, profit, contractor, v.ha(:,:,i), f_yearly);
    NPV(:,i,8) = financial(n_a, n_t, BEAM, gst, cit, i_r_yearly, p_sold, p_pass, profit, contractor, handling, v.f(i));
end

figure
bar(0:12, net)
alternatives = {'DD','CD1','CD2','DN'};
legend(alternatives)

figure
tiledlayout(2,2)
for i = 1:4
    nexttile
    plot(linspace(lower, upper, N).*100, reshape(NPV(i,:,2:8),[N, 7]))
    yline(NPV(i),'k--')
    xlabel('% of Normal')
    ylabel('NPV')
    title(alternatives(i))
end

%% MCDA

function c = linear_ben(col) % 1
    c = col./max(col);
end
function c = vec_ben(col) % 2
    c = col./sqrt(sum(col.^2));
end
function c = lin_cost(col) % 3
    c = (1./col)./max(1./col);
end
function c = vec_cost(col) % 4
    c = (1./col)./sqrt(sum((1./col).^2));
end
function c = nonmonotonic(col, ideal) % 5
    z = (col-ideal)./std(col);
    c = exp(-0.5.*z.^2);
end

% Comparison Matrix
CM(:,:,1) = [
    1	0.333	0.7
    3.003003003	1	1.5
    1.428571429	0.6666666667	1
]; % Social
CM(:,:,2) = [
    1	0.65	0.333
    1.538461538	1	0.9
    3.003003003	1.111111111	1
]; % Strategy
CM(:,:,3) = [
    1	1.4	1.2
    0.7142857143	1	0.7
    0.8333333333	1.428571429	1
]; % Category Comparisons

% Weighting
w = zeros(size(CM,3),3); CI = zeros(size(CM,3),1);
for i = 1:size(CM,3)
    W = zeros(1,size(CM,1));
    W(1,1) = 1;
    eps = 1;
    delta = 1e-6;
    j = 1;

    while eps > delta
        W(j+1,:) = CM(:,:,i)*W(j,:)';
        lambda_max = sum(W(j+1,:));
        W(j+1,:) = W(j+1,:)./lambda_max;
        eps = max(abs(W(j+1,:)-W(j,:)));
        j = j+1;
    end

    w(i,:) = W(end,:); % Weights
    CI(i) = (lambda_max-size(CM,1))/(size(CM,1)-1); % (in)Consistency < 0.1
end
w = [w(3,1), w(1,:).*w(3,2), w(2,:).*w(3,3)];

% Decision Matrix
DM = [
    0.7, 1, 1, 1, 1, 1, NaN;
    0.1, 0.5, 0.33, 3, 4, 1.6, NaN;
    0.1, 0.5, 0.33, 3, 12, 1.8, NaN;
    0.1, 10, 0.1, 1, 24, 0.001, NaN
];

criteria = {'Waste','Appearance','Dust','Demo Time','Project Time','Business','Cost'};
normdict = [3, 3, 3, 3, 3, 1, 4]; % Normalization method for each criteria
idealdict = zeros(size(DM,2)); % Ideal Values
n_c = size(DM,2);


function [SM, NDM] = MCDA(normdict, idealdict, DM, w)
    NDM = zeros(size(DM)); % Normalization
    for k = 1:size(DM,2)
        switch normdict(k)
            case 1
                NDM(:,k) = linear_ben(DM(:,k));
            case 2
                NDM(:,k) = vec_ben(DM(:,k));
            case 3
                NDM(:,k) = lin_cost(DM(:,k));
            case 4
                NDM(:,k) = vec_cost(DM(:,k));
            case 5
                NDM(:,k) = nonmonotonic(DM(:,k), idealdict(k));
        end
    end
    
    % WSM
    wsm_s = sum(w.*NDM,2);
    
    % WPM
    wpm_s = zeros(size(NDM,1));
    for k = 1:size(NDM,1)
        for l = 1:size(NDM,1)
            wpm_s(k,l) = prod((NDM(k,:)./NDM(l,:)).^w,2);
        end
    end
    wpm_s = prod(wpm_s,2);
    
    % TOPSIS
    posid = max(NDM,[],1);
    negid = min(NDM,[],1);
    pos_sep = sqrt(sum(((NDM-posid).*w).^2,2));
    neg_sep = sqrt(sum(((NDM-negid).*w).^2,2));
    topsis_s = neg_sep./(pos_sep+neg_sep);
    SM = [wsm_s, wpm_s, topsis_s];
end

SM = zeros(n_a, 3, N, n_v);
for i = 1:N
    for j = 1:n_v
        DM(:,end) = NPV(:,i,j+1); % Decision matrix construction
        SM(:,:,i,j) = MCDA(normdict, idealdict, DM, w);
    end
end

figure
tiledlayout(4,2,'TileSpacing','tight')
titles = {'MARR','Inflation','%Pass','%Sale','Per-beam Profit','Contractor Cost','Handling cost'};
for i = 1:n_v
    nexttile
    plot(linspace(lower, upper, N).*100, reshape(SM(:,3,:,i), [n_a, N]))
    xlabel('% of Normal')
    ylabel('WSM Score')
    title(titles(i))
end
legend(alternatives)

DM(:,end) = NPV(:,1, 1);
[SMn, NDM] = MCDA(normdict, idealdict, DM, w);

decision_matrix = table(DM(:,1),DM(:,2),DM(:,3),DM(:,4),DM(:,5),DM(:,6),DM(:,7),...
    'RowNames',alternatives,'VariableNames',criteria)

Nt = [w;NDM];
normalized_decision_matrix = table(Nt(:,1),Nt(:,2),Nt(:,3),Nt(:,4),Nt(:,5),Nt(:,6),Nt(:,7),...
    'RowNames',['weight',alternatives],'VariableNames',criteria)

% Rank Analysis
rank = tiedrank(1./sum(SM(:,:,1,1),2)); % Assuming equal bias towards each method
results = table(SM(:,1,1,1),SM(:,2,1,1),SM(:,3,1,1),rank,'VariableNames',...
    {'WSM Score','WPM Score','TOPSIS Score','Overall Rank'},'RowNames',alternatives)
