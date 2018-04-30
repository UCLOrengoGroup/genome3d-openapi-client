# Genome3D API Client
Tool to provide easy access with the [Genome3D](http://www.genome3d.eu) [API](http://www.genome3d.eu/api) on the command line.

## Release Information

This project (and the backend API / database) is currently in a Request For Comments phase and should be considered beta until further notice. Please log issues with GitHub.

## Getting started

#### Get code

```
$ git clone https://github.com/UCLOrengoGroup/genome3d-openapi-client
$ cd genome3d-openapi-client
```

#### Run code

```
$ ./genome3d-api --help
```

#### Dependencies

This project aims to work as a standalone tool, ie the only dependency should be a modern(ish) version of Perl. If running the command above produces errors, then head over to the [Troubleshooting](#Troubleshooting) section or create an issue in GitHub.

## Aims

The Genome3D API consists of a number of **operations** that aim to perform individual tasks such as:

 * "show me all the annotations for a given UniProtKB accession"
 * "let me upload my predicted 3D models for a given UniProtKB sequence"

You can have a look at all the available operations by pointing your browser to the following link:

http://head.genome3d.eu/api

These operations have been defined in a standard format called [OpenAPI](https://www.openapis.org/). As a result, you should be able to get up and running by pointing any OpenAPI compatible client to the specification:

http://head.genome3d.eu/api/openapi.json

This project provides a simple client for convenience (in the form of a simple, command-line tool `genome3d-api`). Hopefully this will make the process of uploading and updating information in Genome3D as simple as possible.

## Usage

```
$ ./genome3d-api -h
USAGE: genome3d-api-client [-h] [long options ...]

    --base_path=String       override the default base path (eg '/api')
    --conf=String            override the default client config file
    --host=String            override the default host (eg 'localhost:5000')
    --mode=String            specify the mode for the data source ([daily] | head | release)
    -o --operation=String    specify operation (eg 'listResources')
    --pdbfiles=[Strings]     specify pdb files for structural prediction
    -r --resource_id=String  specify resource identifier (eg 'SUPERFAMILY')
    -u --uniprot_acc=String  specify uniprot identifier (eg 'P00520')
    -v --verbose             output more details
    --xmlfile=String         specify xml file for domain prediction
                                                                        
    --usage                  show a short help message
    -h                       show a compact help message
    --help                   show a long help message
    --man                    show the manual
```

## Examples

#### Show all the predicted domain annotations for the UniProtKB accession `P00520`:

```
$ ./genome3d-api -o getDomainPrediction -u P00520 -r SUPERFAMILY
```

#### Upload 3D structural predictions (based on the UniProtKB accession `P00520`) to the Genome3D server:

```
$ ./genome3d-api -o updateStructuralPrediction -u P00520 -r SUPERFAMILY \
  --pdbfiles=./example_data/SUPERFAMILY/P00520_62_147.pdb \
  --pdbfiles=./example_data/SUPERFAMILY/P00520_122_262.pdb \
```

In this case, the two PDB files correspond to two separate model regions of the UniProtKB sequence.

#### Upload domain start/stop predictions (based on the UniProtKB accession `P00520`) to the Genome3D server:

```
$ ./genome3d-api -o updateDomainPrediction -u P00520 -r SUPERFAMILY \
  --xmlfile=./example_data/SUPERFAMILY/P00520.xml \
```


## Troubleshooting

### `Can't locate <Module>.pm in @INC ...`

This tool is written in Perl and depends on a number of useful modules.
These modules have been included as part of this project, however if this error
is being reported then it suggests that your machine is having problems accessing
these dependencies (probably due to differences in OS/architecture).

If you have `cpanm`, then executing the following in the root directory of this
project should help:

```
$ cpanm -L extlib --installdeps .
```

If this now works for you, then please consider submitting a PR with the
changes in `extlib`.

### `Sorry, there was an error trying to authentication this client...`

Any operation that involves 'writing' data to the Genome3D server requires authentication (to prove you have 
appropriate permissions to add/update/delete data). See [](#authentication)

## Acknowledgements

 * [Perl](https://www.perl.org/) and tools ([Mojolicious](http://mojolicious.org/), [OpenAPI](https://metacpan.org/pod/Mojolicious::Plugin::OpenAPI), [OAuth2](https://metacpan.org/pod/distribution/Net-OAuth2-AuthorizationServer/lib/Net/OAuth2/AuthorizationServer/Manual.pod))
 * [Swagger](https://swagger.io/) 
