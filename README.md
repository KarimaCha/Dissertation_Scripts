# Dissertation_Scripts

This repository contains computational modeling scripts and task scripts from my dissertation project (*'Dopaminergic modulation of the explore/exploit trade-off in human decision making'*, https://ediss.sub.uni-hamburg.de/volltexte/2019/9835/). The project examined the role of dopamine in human explore/exploit behavior and its neural correlates in a pharmacological fMRI approach. Explore/exploit behavior was assessed with the restless four-armed bandit task and analyzed using different computational reinforcement learning (RL) models in a hierarchical Bayesian modeling approach.


- Task scripts (Matlab) include:
  - restless 4-armed bandit task (bandit_22.m)
  - GUI for Working Memory Test Battery (WM_GUI_Start.m)
  - Listening Span (ListeningSpan.m)
  - Operation Span (OSpan.m)
  - Rotation Span (RotSpan.m)
  - Probability Discounting (PD.m)
  - Delay Discounting (DD.m)


- Bayesian cognitive modeling scripts (R/Stan) include:
  - script to construct data structure for computational modeling (\_dabandit_construct_data.R)
  - script to run computational models (\_dabandit_RL_main.R)
  - scripts for reinforcement learning models (\*.stan)
  - script to analyze outputs from computational modeling (\_dabandit_analyze_outputs.R)
  - script to plot fMRI regressors from computational modeling (\_dabandit_plotRegressors.R)
