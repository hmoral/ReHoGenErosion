# -*- coding: utf-8 -*-
"""
Script to get summary statistics for tree file
"""
import msprime, pyslim, tskit
import numpy as np
import argparse
import allel
#import re

print(msprime.__version__)
print(pyslim.__version__)
print(tskit.__version__)
print(allel.__version__)
#1.0.1
#0.600
#0.3.6
#1.3.5

#### Get arguments
parser = argparse.ArgumentParser()
# Argument parsing to get input values for various variables from the command line
parser.add_argument('--FILEname',nargs='+',type=str)
parser.add_argument('--FILEin',nargs='+',type=str)
parser.add_argument('--geneLength',nargs='+',type=int)
parser.add_argument('--g',nargs='+',type=int)
parser.add_argument('--muChrom_in',nargs='+',type=float)
parser.add_argument('--U_in',nargs='+',type=float)
parser.add_argument('--muFactor',nargs='+',type=int)
parser.add_argument('--Ne',nargs='+',type=int)
parser.add_argument('--maxMig',nargs='+',type=str)
parser.add_argument('--seed',nargs='+',type=int)
parser.add_argument('--SCALE',nargs='+',type=int)

# Assigning the first element from the parsed arguments to variables
args = parser.parse_args()
FILEname=str(args.FILEname[0])
FILEin=str(args.FILEin[0])
geneLength=int(args.geneLength[0])
g=int(args.g[0])
muChrom_in=float(args.muChrom_in[0])
U_in=float(args.U_in[0])
muFactor=int(args.muFactor[0])
Ne=int(args.Ne[0])
maxMig=float(args.maxMig[0])
seed=int(args.seed[0])
SCALE=int(args.SCALE[0])

# Naming convention for output files based on input values
muEnds=FILEin+"_mut_ends.txt"
muFeatures=FILEin+"_mut_features.txt"
muRates=FILEin+"_mut_rates.txt"
recPos=FILEin+"_recPos.txt"
recRates=FILEin+"_recRates.txt"

# Adjusting mutation and recombination rates based on SCALE and muFactor
# SCALE was experimental, assigned always to 1
SCALE=1
muChrom_in=muChrom_in*SCALE
U_in=U_in*SCALE
muChrom_in=muChrom_in/muFactor
U_in=U_in/muFactor
N=Ne*1
popRelativeSize=np.array([0.33,0.33,0.33])
metapop=N*popRelativeSize
type(metapop)
metapop.astype(int)
print(metapop)

# Reading recombination rate and position information from file
with open(recRates) as f:
	RATES=f.readlines()
RATES = [float(x.strip()) for x in RATES]
#RATES.append(0.0)
RATES = [x for x in RATES]

with open(recPos) as f:
	POSITIONS=f.readlines()
POSITIONS = [int(x.strip()) for x in POSITIONS]
POSITIONS.insert(0,0)
POSITIONS[-1]=POSITIONS[-1]+1

# Creating a recombination map using msprime's RateMap class
recomb_map = msprime.RateMap(
  position = POSITIONS,
  rate = RATES)

# Setting up a demographic model for population simulation

demog_model = msprime.Demography()

p=0
for i in metapop:
	print(int(i))
	p=p+1
	demog_model.add_population(
		name="p"+str(p),
		initial_size=int(i))

migRates=np.array([0.02,0.05])*maxMig

for i in range(1,(len(metapop))):
    print(i)
    print(("pop:"+ str(i+1) + " take from:" + str(i) + " N:"+ str(migRates[i-1])))
    demog_model.set_migration_rate(source="p"+str(i), dest="p"+str(i+1), rate=migRates[i-1])
    print(("pop:"+ str(i) + " take from:" + str(i+1) + " N:"+ str(migRates[i-1])))
    demog_model.set_migration_rate(source="p"+str(i+1), dest="p"+str(i), rate=migRates[i-1])

print("sim_ancestry")
# Simulating ancestry using msprime's sim_ancestry function, with population sizes from the demographic model
ots = msprime.sim_ancestry(
		samples={"p1": int(metapop[0]),"p2": int(metapop[1]),"p3": int(metapop[2])},
		demography=demog_model,
		random_seed=seed,
		recombination_rate=recomb_map)

ots = pyslim.annotate_defaults(ots, model_type="nonWF", slim_generation=1)

# Counting the number of individuals in the simulated tree sequence
count=0
for i in ots.individuals():
	count=count+1

print("individuals in tree="+str(count))

# Calculating  mutation rates based on neutral to deleterious proportions
Glen=float(geneLength*g)
print("Glen:"+str(Glen))
print("U_in:"+str(U_in))
mu=U_in/(2*Glen)
mu_intron=muChrom_in*(1/1.2)
mu_exon=muChrom_in*(1/3.31)
mu_interGen=muChrom_in
mu_exome=mu*(1/3.31)


# Reading mutation positions and rates and genomic features (intron, exon, integeneic) from files

with open(muEnds) as f:
	mu_Ends=f.readlines()
mu_Ends = [int(x.strip()) for x in mu_Ends]
mu_Ends = [x +1 for x in mu_Ends]
mu_Ends.insert(0,0)

with open(muRates) as f:
	mu_Rates=f.readlines()
mu_Rates = [float(x.strip()) for x in mu_Rates]
#mu_Rates = [x/genTime for x in mu_Rates]


with open(muFeatures) as f:
	mu_Feat=f.readlines()
mu_Feat = [str(x.strip()) for x in mu_Feat]
#mu_Rates = [x/genTime for x in mu_Rates]


# define mutation rates based on imput and proportions
Glen=float(geneLength*g)
print("Glen:"+str(Glen))
print("U_in:"+str(U_in))
mu=U_in/(2*Glen)
mu_intron=muChrom_in*(1/1.2)
mu_exon=muChrom_in*(1/3.31)
mu_interGen=muChrom_in
mu_exome=mu*(1/3.31)

print("mutation rates:")
print("mutation chrom:"+str(muChrom_in))
print("mutation exome:"+str(mu))


# mu rates based on feature (intron, exon, intron) distribution
mu_Feat=[mu_intron if x=='intron' else x for x in mu_Feat]
mu_Feat=[mu_exon if x=='exon' else x for x in mu_Feat]
mu_Feat=[mu_interGen if x=='interGen' else x for x in mu_Feat]
mu_Feat=[mu_exome if x=='exome' else x for x in mu_Feat]

# mu rates = mu edited mu features
mu_Rates=mu_Feat

print("sim_mutations")
# Defining mutation rate map and simulation parameters, and simulating mutations on the tree sequence
mut_map=msprime.RateMap(position=mu_Ends, rate=mu_Rates)
GENS=int(1e7)
mut_model = msprime.SLiMMutationModel(type=1,slim_generation=GENS,next_id=1)
ots = msprime.sim_mutations(
			ots,
			rate=mut_map,
			model=mut_model,
			keep=True,
			random_seed=seed)
print(f"The tree sequence now has {ots.num_mutations} mutations, at "
	  f"{ots.num_sites} distinct sites.")

# Extracting SLiM mutation times before the present from the mutation metadata (sanity check)
slimTIMES_before=[]
for mut in ots.mutations():
    md = mut.metadata["mutation_list"][0]["slim_time"]
    slimTIMES_before.append(md)

#slimTIMES_before.sort()
#slimTIMES_before[0:10]

print("mutation gen time smaller than 0")
print(len([1 for i in slimTIMES_before if i < 0]))


# Formatting values for output and creating file names for output
muChrom_in="%.2g" % muChrom_in
mu="%.2g" % mu
U_in="%.2g" % U_in

seqLen=int(ots.sequence_length)
migRATES=str(migRates[0])+"_"+str(migRates[1])
outVAR=FILEname+"_muFactor"+str(muFactor)+"_U"+str(U_in)+"_muChr"+str(muChrom_in)+"_muEx"+str(mu)+"_Ne"+str(Ne)+"_maxMig"+str(maxMig)+"_MigRates"+str(migRATES)+"_seqLen"+str(seqLen)+"_msprime"
VARfile=FILEname+"_set_variables.sh"
FILEname=FILEname+"_muFactor"+str(muFactor)+"_U"+str(U_in)+"_muChr"+str(muChrom_in)+"_muEx"+str(mu)+"_Ne"+str(Ne)+"_maxMig"+str(maxMig)+"_MigRates"+str(migRATES)+"_seqLen"+str(seqLen)+"_msprime.tree"

print('Output '+FILEname)
ots.dump(FILEname)
seqLen=str(seqLen)

#creating variable file for following steps
with open(VARfile, "w") as file:
    file.write(f"export FILE='{outVAR}'\n")
    file.write(f"export chrSize='{seqLen}'\n")

