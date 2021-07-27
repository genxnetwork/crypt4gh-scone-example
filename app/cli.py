#!/usr/bin/env python3
import sys
import io

import click
import crypt4gh.lib
from nacl.public import PrivateKey
from nacl.encoding import HexEncoder
import vcfpy


@click.group()
def cli():
    """Crypt4GH encryption and encrypted file processing example."""


@cli.command()
@click.option("--sender", required=True, envvar="SENDER_KEY")
@click.option("--recipient", required=True, envvar="RECIPIENT_KEY")
@click.argument("infile", type=click.File("rb"), default=sys.stdin.buffer)
@click.argument("outfile", type=click.File("wb"), default=sys.stdout.buffer)
def encrypt(sender, recipient, infile, outfile):
    """Encrypt input."""
    private_key = load_key(sender).encode()
    recipient_key = load_key(recipient).public_key.encode()
    crypt4gh.lib.encrypt(
        keys=[(0, private_key, recipient_key)],
        infile=infile,
        outfile=outfile,
    )


@cli.command()
@click.option("--sender", required=False, envvar="SENDER_KEY", default=None)
@click.option("--recipient", required=True, envvar="RECIPIENT_KEY")
@click.argument("infile", type=click.File("rb"), default=sys.stdin.buffer)
@click.argument("outfile", type=click.File("w"), default=sys.stdout)
def process(sender, recipient, infile, outfile):
    """Process encrypted input."""
    key = load_key(recipient).encode()
    sender_pubkey = load_key(sender).public_key.encode() if sender else None
    stream = io.BytesIO()
    crypt4gh.lib.decrypt(
        [(0, key, None)], infile=infile, outfile=stream, sender_pubkey=sender_pubkey
    )
    stream.seek(0)
    process_stream(stream, outfile)


def process_stream(stream: io.BytesIO, outfile: io.TextIOWrapper):
    """File processing: extract ID's from the VCF file stream."""
    for row in vcfpy.Reader(io.TextIOWrapper(stream)):
        try:
            outfile.writelines((row.ID[0], "\n"))
        except IndexError:
            continue


def load_key(key: str) -> PrivateKey:
    """Load PrivateKey from a hex string."""
    return PrivateKey(key, encoder=HexEncoder)


if __name__ == "__main__":
    cli()
