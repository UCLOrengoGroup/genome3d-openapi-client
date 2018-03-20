# genome3d-api-client
Tool to interact with the Genome3D API

## Setup

```
$ git clone https://github.com/UCLOrengoGroup/genome3d-openapi-client
$ cd genome3d-openapi-client
```

## Usage

```
$ ./genome3d-api-client -h
USAGE: genome3d-api-client [-h] [long options ...]

    --conf=String            override the default client config file
    --host=String            override the default host (eg 'localhost:5000')
    -o --operation=String    specify operation (eg 'listResources')
    --pdbfiles=String        specify pdb file for structural prediction
    -r --resource_id=String  specify resource identifier (eg 'SUPERFAMILY')
    -u --uniprot_acc=String  specify uniprot identifier (eg 'P00520')
    --xmlfile=String         specify xml file for domain prediction

    --usage                  show a short help message
    -h                       show a compact help message
    --help                   show a long help message
    --man                    show the manual
```

## Available Operations

```
$ ./genome3d-api-client

Available operations:
  addDomainPrediction                      Add a new domain prediction
    params: uniprot_acc=<string> resource_id=<string> xmlfile=<file>

  addStructurePrediction                   Add a new 3D structure prediction
    params: uniprot_acc=<string> resource_id=<string> pdbfiles=<file>

  deleteDomainPrediction                   Deletes a domain prediction
    params: uniprot_acc=<string> resource_id=<string>

  deleteStructurePrediction                Deletes a 3D structure prediction
    params: uniprot_acc=<string> resource_id=<string>

  getClassificationDomain                  Get information about a particular domain from a classification release
    params: release_id=<string> domain_id=<string>

  getDomainPrediction                      Get domain prediction(s) for a given UniProtKB / Resource
    params: uniprot_acc=<string> resource_id=<string>

  getStructurePrediction                   Get structural prediction(s) for a given UniProtKB / Resource
    params: uniprot_acc=<string> resource_id=<string>

  getUniprot                               Find UniProtKB sequence by accession
    params: uniprot_acc=<string>

  getUserByName                            Get user by user name
    params: username=<string>

  listClassificationReleases               List all the releases of domain classifications

  listResources                            List resources

  listStructurePredictions                 List all structural prediction(s) for a given UniProtKB entry
    params: uniprot_acc=<string>

  loginUser                                Logs user into the system
    params: username=<string> password=<string>

  logoutUser                               Logs out current logged in user session

  updateDomainPrediction                   Update an existing domain prediction
    params: uniprot_acc=<string> resource_id=<string> xmlfile=<file>

  updateStructurePrediction                Update an existing 3D structure prediction
    params: uniprot_acc=<string> resource_id=<string> pdbfiles=<file>

```
