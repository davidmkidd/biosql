
#added process_id to job - all the jobs associated with a single pipeline run are identified by this process_id


CREATE TABLE job (
  job_id             int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
  process_id         varchar(100) DEFAULT 'NEW' NOT NULL,
  analysis_id        int(10) unsigned DEFAULT '0',
  queue_id           int(10) unsigned DEFAULT '0',
  stdout_file        varchar(100) DEFAULT '',
  stderr_file        varchar(100) DEFAULT '',
  object_file        varchar(100) DEFAULT '',
  status             varchar(20) DEFAULT 'NEW' NOT NULL,
  stage              varchar(20) DEFAULT '',
  time               datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  retry_count        int default 0,

  PRIMARY KEY (job_id),
  KEY (process_id),
  KEY (analysis_id)
);

CREATE TABLE dynamic_argument(
  input_id             int(10) unsigned DEFAULT '0' NOT NULL ,
  datahandler_id     int(10) unsigned NOT NULL,
  tag             varchar(40) DEFAULT '',
  value           varchar(40) DEFAULT '',
  rank            int(10) DEFAULT 1 NOT NULL,
  type            enum('SCALAR','ARRAY') DEFAULT 'SCALAR' NOT NULL,

  PRIMARY KEY (input_id,datahandler_id,rank),
  KEY(datahandler_id)
);

CREATE TABLE input_create_argument (
  input_create_argument_id    int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
  input_create_id    int(10) unsigned DEFAULT '0' NOT NULL ,
  tag             varchar(40) DEFAULT '',
  value           varchar(40) DEFAULT '',

  PRIMARY KEY (input_create_argument_id)
);

CREATE TABLE filter_argument (
  filter_argument_id    int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
  filter_id    int(10) unsigned DEFAULT '0' NOT NULL ,
  tag             varchar(40) DEFAULT '',
  value           varchar(40) DEFAULT '',

  PRIMARY KEY (filter_argument_id)
);


CREATE TABLE filter (
  filter_id int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
  data_monger_id int(10) unsigned DEFAULT '0' NOT NULL ,
  module varchar(40) DEFAULT '',
  rank            int(10) DEFAULT 1 NOT NULL,
  
  PRIMARY KEY(filter_id)
);

CREATE TABLE input_create (
  input_create_id  int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
  data_monger_id int(10) unsigned DEFAULT '0' NOT NULL ,
  module varchar(40) DEFAULT '' NOT NULL,
  rank            int(10) DEFAULT 1 NOT NULL,
  
  PRIMARY KEY(input_create_id)
);
  
CREATE TABLE iohandler (
   iohandler_id         int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
   adaptor_id           int(10) DEFAULT '0' NOT NULL,
   type                 enum ('INPUT','CREATE_INPUT','OUTPUT','NEW_INPUT') NOT NULL,
   adaptor_type         enum('DB','STREAM') DEFAULT 'DB' NOT NULL,

   PRIMARY KEY (iohandler_id),
   KEY adaptor (adaptor_id)
);

# note-  the column type is meant for differentiating the input adaptors from the output adaptors
#        each analysis should only have ONE output adaptor.

CREATE TABLE datahandler(
    datahandler_id     int(10) unsigned NOT NULL auto_increment,
    iohandler_id        int(10) DEFAULT '0' NOT NULL,
    method              varchar(60) DEFAULT '' NOT NULL,
    rank                int(10) DEFAULT 1 NOT NULL,

    PRIMARY KEY (datahandler_id),
    KEY iohandler (iohandler_id)
);

CREATE TABLE argument (
  argument_id     int(10) unsigned NOT NULL auto_increment,
  datahandler_id  int(10) unsigned NOT NULL ,
  tag             varchar(40) DEFAULT '',
  value           varchar(40) DEFAULT '',
  rank            int(10) DEFAULT 1 NOT NULL,
  type            enum('SCALAR','ARRAY') DEFAULT 'SCALAR' NOT NULL,

  PRIMARY KEY (argument_id)
);

CREATE TABLE dbadaptor (
   dbadaptor_id   int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
   dbname         varchar(40) DEFAULT '' NOT NULL,
   driver         varchar (40) DEFAULT '' NOT NULL,
   host           varchar (40) DEFAULT '',
   port           int(10) unsigned  DEFAULT '',
   user           varchar (40) DEFAULT '',
   pass           varchar (40) DEFAULT '',
   module         varchar (100) DEFAULT '',
   
   PRIMARY KEY (dbadaptor_id)
);

CREATE TABLE streamadaptor (
  streamadaptor_id  int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
  module          varchar(40) DEFAULT '' NOT NULL,

  PRIMARY KEY (streamadaptor_id)
);

#modified input table to reflect only Fixed Inputs (Inputs that are filled up before the pipeline run
# and are different from the inputs generated during pipeline run

#caters for multiple inputs across diffferent analysis using different iohandlers
CREATE TABLE input (
   input_id         int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
   name             varchar(40) DEFAULT '' NOT NULL,
   tag              varchar(40) DEFAULT '',
   job_id           int(10) unsigned NOT NULL,
   iohandler_id     int(10) unsigned ,

   PRIMARY KEY (input_id),
   KEY iohandler (iohandler_id),
   KEY job (job_id)

);


CREATE TABLE output (
  job_id           int(10) unsigned DEFAULT '0' NOT NULL,
  output_name             varchar(40) DEFAULT '' NOT NULL,
  PRIMARY KEY (job_id, output_name)
);


# created new table to reflect the inputs generated (as outputs of an analysis)- currently an analysis can generate
# outputs as inputs only for the next analysis  

CREATE TABLE new_input (
  input_id         int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
  job_id           int(10) unsigned DEFAULT '0' NOT NULL,
  name             varchar(40) DEFAULT '' NOT NULL,
  PRIMARY KEY (input_id)
  #PRIMARY KEY (job_id,name,new_input_ioh_id);
  
);

# Replaced Rule_goal and Rule_condition tables with rule table
# Different actions and their behavior
# NOTHING - the output of the previous analysis is not to be used as the input and so just use the fixed inputs that
# were set during the start of the pipeline
# UPDATE - convert the outputs of the previous analysis as inputs to the next analysis -creates one job per input
# WAITFORALL - the new job for the next analysis will be created only when all the jobs of the previous analysis are
# completed, the outputs of the previous jobs are not set as inputs to the next job
# WAITFORALL_AND_UPDATE - same as WAITFORALL but the outputs are set as inputs for the next job

CREATE TABLE rule (
  rule_id          int(10) unsigned DEFAULT'0' NOT NULL auto_increment,
  current          int(10) unsigned DEFAULT '',
  next             int(10) unsigned NOT NULL,
  action           enum('WAITFORALL','WAITFORALL_AND_UPDATE','UPDATE','NOTHING','COPY_INPUT','COPY_ID','CREATE_INPUT'),
  
  PRIMARY KEY (rule_id)
);


CREATE TABLE analysis (
  analysis_id      int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
  created          datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  logic_name       varchar(40) not null,
  runnable         varchar(80),
  db               varchar(120),
  db_version       varchar(40),
  db_file          varchar(120),
  program          varchar(80),
  program_version  varchar(40),
  program_file     varchar(80),
  data_monger_id   int(10) unsigned DEFAULT '',
  parameters       varchar(80),
  gff_source       varchar(40),
  gff_feature      varchar(40),
  node_group_id    int(10) unsigned DEFAULT '0' NOT NULL,

  PRIMARY KEY (analysis_id)
);

#This tables can be used in three semantically different ways 
#depending on the type of iohandler linked to the analysis
#type INPUT_CREATE: used for fetching the ids and populating the inputs for the analysis
#type INPUT: used to specify the iohandler to be used for the analysis (if not fixed or from output)
#type OUTPUT: used to specify the output iohandler to store the output

CREATE TABLE analysis_iohandler(
  analysis_id               int(10) NOT NULL,
  iohandler_id              int(10) NOT NULL,
  converter_id              int(10) ,
  converter_rank                      int(2) ,
  #PRIMARY KEY (analysis_id,iohandler_id,converter_id)
  UNIQUE (analysis_id,iohandler_id,converter_id)

);

CREATE TABLE converter (
  converter_id		int(10) unsigned DEFAULT'0' NOT NULL auto_increment,
  module		varchar(255) NOT NULL,
  method                varchar(255) NOT NULL,

  PRIMARY KEY (converter_id)
);

CREATE TABLE completed_jobs (
  completed_job_id      int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
  process_id         varchar(100) DEFAULT 'NEW' NOT NULL,
  analysis_id           int(10) unsigned DEFAULT '0',
  queue_id              int(10) unsigned DEFAULT '0',
  stdout_file           varchar(100) DEFAULT '' NOT NULL,
  stderr_file           varchar(100) DEFAULT '' NOT NULL,
  object_file           varchar(100) DEFAULT '' NOT NULL,
  time                  datetime DEFAULT '0000-00-00 00:00:00' NOT NULL,
  retry_count           int default 0,

  PRIMARY KEY (completed_job_id),
  KEY analysis (analysis_id)
);

#Added tables for node groups for use in Analysis-based allocation of jobs

CREATE TABLE node (
  node_id               int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
  node_name             varchar(40) DEFAULT '' NOT NULL,
  group_id              int(10) unsigned DEFAULT '0' NOT NULL,

  PRIMARY KEY (node_id,group_id)
);

CREATE TABLE node_group (
  node_group_id         int(10) unsigned NOT NULL auto_increment,
  name                  varchar(40) NOT NULL,
  description           varchar(255) NOT NULL,

  PRIMARY KEY (node_group_id),
  KEY (name)
);

CREATE TABLE iohandler_map(
 prev_iohandler_id             int(10) NOT NULL,
 analysis_id                   int(10) NOT NULL,
 map_iohandler_id              int(10) NOT NULL,

 PRIMARY KEY (prev_iohandler_id,analysis_id)
);
