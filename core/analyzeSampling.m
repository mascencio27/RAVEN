function scores=analyzeSampling(Tex, df, solutionsA, solutionsB, printResults)
% analyzeSampling
%   Compares the significance of change in flux between two conditions with
%   the significance of change in gene expression
%
%   Tex             a vector of t-scores for the change in gene expression
%                   for each reaction. This score could be the Student t
%                   between the two conditions, or you can calculate it from
%                   a p-value (by computing the inverse of the so called error
%                   function). If you choose the second alternative you should
%                   be aware that the transcripts that increased in expression
%                   level should have positive values and those who decreased
%                   in expression level should have negative values (the
%                   p-values only tell you if the fluxes changed or not but
%                   not in which direction)
%   df              the degrees of freedom in the t-test
%   solutionsA      random solutions for the reference condition (as
%                   generated by randomSampling)
%   solutionsB      random solutions for the test condition (as generated
%                   by randomSampling)
%   printResults    prints the most significant reactions in each category
%                   (opt, default false)
%
%   scores          a Nx3 column matrix with the probabilities of a reaction:
%                   1) changing both in flux and expression in the same direction
%                   2) changing in expression but not in flux
%                   3) changing in flux but not in expression or changing
%                      in opposed directions in flux and expression.
%
%   Usage: scores=analyzeSampling(Tex, df, solutionsA, solutionsB, printResults)
%
%   Rasmus Agren, 2014-01-08
%

if nargin<5
    printResults=false;
end

nRxns=numel(Tex);
pM=zeros(nRxns,1);
pH=zeros(nRxns,1);
pR=zeros(nRxns,1);

%Check that the number of reactions is the same in both expression and flux
if nRxns~=size(solutionsA,1)
    EM='The number of reactions must be the same in Tex as in solutionsA';
    dispEM(EM);
end

%Get the Z-score and mean for the solutions
mA=mean(solutionsA,2);
mB=mean(solutionsB,2);
Zf=getFluxZ(solutionsA, solutionsB);

%Clear up the tex if there are elements that are NaN or +/- Inf.
I=isnan(Tex) | isinf(Tex);
if any(I)
    EM='There are t-scores that are NaN or +/- Inf. These values are changed to 0.0';
    dispEM(EM,false);
end
Tex(I)=0;

for i=1:nRxns
    %Check how the flux has changed. The means are needed because to
    %differentiate between a positive flux changing to a smaller flux and a
    %negative flux changing to a more negative flux (which is a larger
    %flux)
    I=mB(i)/mA(i);
    if I<0
        pM(i)=erf(abs(Zf(i)));
        pH(i)=(1-pM(i))*(2*tcdf(abs(Tex(i)),df)-1);
        pR(i)=0;
    else
        if mB(i)<0
            Zf(i)=Zf(i)*-1;
        end
    end
    
    I=Zf(i)/Tex(i);
    if I<0
        pM(i)=erf(abs(Zf(i)));
        pH(i)=(1-pM(i))*(2*tcdf(abs(Tex(i)),df)-1);
        pR(i)=0;
    else
        pR(i)=erf(abs(Zf(i)))*(2*tcdf(abs(Tex(i)),df)-1);
        pH(i)=(2*tcdf(abs(Tex(i)),df)-1)*(1-erf(abs(Zf(i))));
        pM(i)=erf(abs(Zf(i)))*(1-(2*tcdf(abs(Tex(i)),df)-1));
    end
end

scores=[pR pH pM];

if printResults==true
    fprintf('TOP SCORING REACTIONS\n\n');
    %The top 10 hits in the first category
    [I, J]=sort(pR,'descend');
    fprintf('Reactions which change both in flux and expression in the same direction\nReaction\tProbability\n');
    for i=1:10
        fprintf([num2str(J(i)) '\t' num2str(I(i)) '\n']);
    end
    
    %The top 10 hits in the first category
    [I, J]=sort(pH,'descend');
    fprintf('\nReactions which change in expression but not in flux\nReaction\tProbability\n');
    for i=1:10
        fprintf([num2str(J(i)) '\t' num2str(I(i)) '\n']);
    end
    
    %The top 10 hits in the first category
    [I, J]=sort(pM,'descend');
    fprintf('\nReactions which change in flux but not in expression, or in opposed directions in flux and expression\nReaction\tProbability\n');
    for i=1:10
        fprintf([num2str(J(i)) '\t' num2str(I(i)) '\n']);
    end
end
end
