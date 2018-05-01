# Genome3D API Client
Tool to provide easy access with the [Genome3D](http://www.genome3d.eu) [API](http://www.genome3d.eu/api) on the command line.

**Current Status: Request For Comments (RFC)**

This project is currently in a "request for comments" phase. **All code, backend API and data may be changed without notice** and should not be included in production code. Please regularly update your local repository to get the latest changes. At the end of the **RFC** phase, a stable version will be released for **BETA** testing.

Please log problems and feature requests as GitHub Issues.

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

This project aims to work as a standalone tool: the only dependency should be having access to a relatively modern version of Perl. If running the command above produces an error, then head over to the [Troubleshooting](#Troubleshooting) section or create an issue in GitHub.

## Overview

The Genome3D API consists of a number of **operations** that aim to perform tasks such as:

 * "Show me all the annotations for a given UniProtKB accession"
 * "Let me upload my predicted 3D models for a given UniProtKB sequence"

You can have a look at all the available operations by pointing your browser at:

http://head.genome3d.eu/api

The code in this project provides a simple command-line tool `genome3d-api` that aims to make communicating with the Genome3D API as convenient as possible. However, since the API has been defined in a standard format [OpenAPI](https://www.openapis.org/), you should be able to point any OpenAPI-compatible client to the following specification file:

http://head.genome3d.eu/api/openapi.json

Note: this is a polite way of saying - if you don't like the code in this project you are welcome to write your own ;)

## Usage

```
$ genome3d-api -h
USAGE: genome3d-api [-h] [long options ...]

    --mode=String            specify the mode for the data source
                             (daily|head|release) [daily]
                                                                        
    -l --list                list all the available operations
                                                                        
    -o --operation=String    specify operation (eg 'listResources')
    --pdbfiles=[Strings]     specify pdb files for structural prediction
    -r --resource_id=String  specify resource identifier (eg 'SUPERFAMILY')
    -u --uniprot_acc=String  specify uniprot identifier (eg 'P00520')
    --xmlfile=String         specify xml file for domain prediction
                                                                        
    --base_path=String       override the default base path [/api])
    --conf=String            override the default config file
                             [client_config.json]
    --host=String            override the default host (eg 'localhost:5000')
                                                                        
    -q --quiet               output fewer details
    -v --verbose             output more details
                                                                        
    --usage                  show a short help message
    -h                       show a compact help message
    --help                   show a long help message
    --man                    show the manual
```

Many of these options can be safely ignored, the following will be used frequently.

#### `--list`
List all available operations

#### `--mode=<daily|head|release>`
**IMPORTANT:** The `mode` determines which backend database will be used for API calls. The default setting is `--mode=daily` which is useful for testing only (since all changes are wiped every day).

| Mode | Role | Read/Write | Description | Web |
|--|--|--|--|--|
| `daily` *(default)* | TESTING | Read/Write | Updated every day from `head` | [link](daily.genome3d.eu) |
| `head` | LIVE | Read/Write | Contains data that will make it into the next release | [link](head.genome3d.eu) |
| `latest` | RELEASE | Read Only | Contains data from the most recent release (ie the data currently available on the main Genome3D web site) | [link](www.genome3d.eu) |

Note: corresponding web pages are available for each of these modes (web link above).

#### `-o --operation`
The name of the API **operation** you want to perform (see `--list` for a list of all operations and parameters)

#### `-u --uniprot_acc`
Most operations require a particular UniProtKB accession to be specified.

#### `-r --resource_id`
Specify which resource to use (you can *read* data from any resource, but you can only *write* data to your own resource).

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

Note: in this case, the two PDB files correspond to two separate model regions of the UniProtKB sequence.

#### Upload domain start/stop predictions (based on the UniProtKB accession `P00520`) to the Genome3D server:

```
$ ./genome3d-api -o updateDomainPrediction -u P00520 -r SUPERFAMILY \
  --xmlfile=./example_data/SUPERFAMILY/P00520.xml \
```

## Testing

The 

## Authentication

Since the API lets users make changes to the Genome3D database, it is important to make sure people only change their own data. As such, each contributing group needs to have their own uniquely identifying information (which will be sent out seperately to each contributor and should be kept secret).

Once you have been given your details, you should ammend the file `client_config.json`.

```json
{
  "resource":      "<RESOURCE_ID>",
  "username":      "<RESOURCE_USER>",
  "password":      "<RESOURCE_SECRET>",
  "client_secret": "<CLIENT_SECRET>"
}
```

This will now allow you to perform authenticated operations (ie **ADD**, **UPDATE**, **DELETE** your own data) as well as the **GET** operations that allow everyone to read information from the database.

## Troubleshooting

### `Can't locate <Module>.pm in @INC ...`

This tool is written in Perl and depends on a number of useful modules.
These modules have been included as part of this project, however if this error
is being reported then it suggests that your machine is having problems accessing
these dependencies (probably due to differences in OS/architecture).

If you have the `cpanm` tool available, then executing the following in the root directory of this project should help:

```
$ cpanm -L extlib --installdeps .
```

If this now works for you, then please consider submitting a PR with the changes in `./extlib`.

### `Sorry, there was an error trying to authentication this client...`

Any operation that involves 'writing' data to the Genome3D server requires authentication (to prove you have 
appropriate permissions to add/update/delete data). See the [authentication section](#authentication).


## Acknowledgements

 * [Perl](https://www.perl.org/) and tools ([Mojolicious](http://mojolicious.org/), [OpenAPI](https://metacpan.org/pod/Mojolicious::Plugin::OpenAPI), [OAuth2](https://metacpan.org/pod/distribution/Net-OAuth2-AuthorizationServer/lib/Net/OAuth2/AuthorizationServer/Manual.pod))
 * [Swagger](https://swagger.io/) 
