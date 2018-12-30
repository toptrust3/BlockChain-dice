# -*- coding: utf-8 -*-
import os
import sys
import web3
import django
import datetime
import random
import uuid
import time

from web3.auto import w3

from datetime import timedelta
from django.utils import timezone

from django.conf import settings
from django.core import serializers
from django.http import JsonResponse, HttpResponseRedirect, HttpResponse
from django.shortcuts import render, redirect, get_object_or_404

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "dice.settings")
django.setup()

from dice.models import Bets
from dice.models import Players

from web3 import Web3, Account
from web3.providers.rpc import HTTPProvider

import logging
logger = logging.getLogger(__name__)


def home(request):

    player_wallet = None

    try:
        session_key = request.COOKIES["session_key"]
    except:
        session_key = uuid.uuid4()

    print('session_key', session_key)

    try:
        player = Players.objects.get(session_key=session_key)
        player_session_key = player.session_key
        player_wallet = player.address
    except Players.DoesNotExist:
        player_session_key = session_key

    # XXX TODO filter for paired transactions (status=1, tx_hash and player is not empty)
    # XXX TODO pretriedit transakce aby tie nie-vyherne boli menej frequentne
    games = Bets.objects.filter().order_by('-pk')[:100]
    my_games = Bets.objects.filter(player=player_wallet).order_by('-pk')[:100]
    # XXX TODO zredukuj list povuhadzuj z neho len par tych co prehrali.....
    # XXX todo potrebujem player wallet info aby som mohol toto spravit....
    #my_games = Bets.objects.filter(player="0xeacd131110FA9241dEe05ccf3e3635D12f629A3b".lower()).order_by("-pk")
    #my_games = []

    response = render(
        request=request,
        template_name='index.html',
        context={
            'contract': settings.ETHEREUM_DICE_CONTRACT,
            'contract_abi': settings.ETHEREUM_DICE_CONTRACT_ABI,
            'games': games,
            'my_games': my_games,
            'player_session_key': player_session_key,
            'player_wallet': player_wallet,
            },
    )
    response.set_cookie(key="session_key",value=session_key)

    return response


def get_game_abi(request):

    return HttpResponse(settings.ETHEREUM_DICE_CONTRACT_ABI)


def get_game_contract(request):

    if('ropsten' in settings.ETHEREUM_PROVIDER_HOST):
        etherscan_url = "https://ropsten.etherscan.io/address/"+settings.ETHEREUM_DICE_CONTRACT
    else:
        etherscan_url = "https://etherscan.io/address/"+settings.ETHEREUM_DICE_CONTRACT

    return HttpResponseRedirect(etherscan_url)


def ajax_bet(request):
    
    player_wallet = request.POST.get('wallet')
    bet_tx_hash = request.POST.get('value')
    bet_amount = request.POST.get('amount')

    bet_numbers = request.POST.getlist('numbers[]')

    _bet_numbers = []
    for _number in  bet_numbers:
        _bet_numbers.append(int(_number))
    bet_numbers = _bet_numbers

    Bets.objects.create(
        player = player_wallet,
        tx_hash = bet_tx_hash,
        amount = bet_amount,
        numbers = str(bet_numbers),
    )

    return HttpResponse('Ok')


def ajax_update_player_wallet(request):

    player_wallet = request.POST.get('wallet')
    player_session_key = request.POST.get('player_session_key')

    Players.objects.get_or_create(session_key=player_session_key)
    player = Players.objects.get(session_key=session_key)
    player.address = player_wallet
    player.save()

    return HttpResponse('Ok')



def ajax_my_games(request):
    # XXX todo filter my games
    return JsonResponse([], safe=False)

def ajax_all_games(request):
    # XXX todo ajax call to list games table
    return JsonResponse([], safe=False)


