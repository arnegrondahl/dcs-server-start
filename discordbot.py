from discord.ext import commands
from discord_slash import SlashCommand
from discord_slash.utils.manage_commands import create_option
import logging
import boto3
import yaml
import time # for sleep only

logging.basicConfig(level=logging.INFO)

with open(r'config.yaml') as file:
    configfile = yaml.load(file, Loader=yaml.FullLoader)
    #print(configfile)

bot = commands.Bot(command_prefix='!')
slash = SlashCommand(bot, sync_commands=True) # Declares slash commands through the client.
guild_id = [xx] # Server id here
ec2_client = boto3.client('ec2')

instance_test = {
    'id': 'i-123xyz',
    'display_name': 'Viktor Röd TEST',
    'public_ip': '0.0.0.0'
}

instance_prod = {
    'id': 'i-123abc',
    'display_name': 'Viktor Röd PROD',
    'public_ip': '0.0.0.0'
}

instance_current = instance_prod

def ec2_get_status(env):
    r = ec2_client.describe_instances(InstanceIds=[env['id']])

    instance_details = {
    'id': r['Reservations'][0]['Instances'][0]['InstanceId'],
    'display_name': env['display_name'],
    'public_ip': env['public_ip'],
    'state': r['Reservations'][0]['Instances'][0]['State']['Name']
    }

    return instance_details

def ec2_send_command(env, command):
    if command == 'start':
        r = ec2_client.start_instances(InstanceIds=[env['id']])
        return_value = "Sent start request to {}, instance {}, public IP {}, current state {}".format(env['display_name'], env['id'], env['public_ip'], r['StartingInstances'][0]['CurrentState']['Name'])

    elif command == 'stop':
        r = ec2_client.stop_instances(InstanceIds=[env['id']])
        return_value = "Sent stop request to {}, instance {}, public IP {}, current state {}".format(env['display_name'], env['id'], env['public_ip'], r['StoppingInstances'][0]['CurrentState']['Name'])

    else:
        print("didnt match either start or stop")

    return return_value


def ec2_retry_check(env, to_state):
    time_elapsed = 0
    while True:
        # Retrieve the EC2 instance state
        instance_details = ec2_get_status(env)
        instance_state = instance_details['state']

        if time_elapsed >= 120:
            print("timeout reached.. returning timeout")
            return ("- Error: check timed out to prevent infinite loop. Run a /status to check status yourself!")

        elif instance_state != to_state:
            print("instance state is '{}', waiting for '{}'...".format(instance_state, to_state))
            time.sleep(5)
            time_elapsed = time_elapsed + 5

        elif instance_state == to_state:
            print("instance_state is now eq to to_state, returning instance_state")
            return instance_state


@bot.event
async def on_ready():
    print(f'Logged in as {bot.user.name} - {bot.user.id}')

@slash.slash(name="ping",
             guild_ids=guild_id,
             description = "Give us a ping and get a pung"
             )
async def _ping(ctx): # Defines a new "context" (ctx) command called "ping."
    await ctx.send(f"Pong! ({bot.latency*1000}ms)")
    print("received ping.. ponged")


@slash.slash(name="status",
             guild_ids=guild_id,
             description = "Report if the VM is up or down (running or stopped)"
             )
async def _status(ctx): # Defines a new "context" (ctx) command called "status."
    run = (ec2_get_status(instance_current))
    message = ("Status {}, {}, {}, state: {}".format(run['display_name'], run['id'], run['public_ip'], run['state']))
    await ctx.send(message)

@slash.slash(name="start",
             guild_ids=guild_id,
             description = "Start VM"
             )
async def _start(ctx): # Defines a new "context" (ctx) command called "start."
    run = ec2_send_command(instance_current, 'start')
    await ctx.send(run)

    desired_state = 'running'
    time_elapsed = 0
    time_check_interval = 2
    timeout_value = 120

    while True:
        # Retrieve the EC2 instance state
        instance_details = ec2_get_status(instance_current)
        instance_state = instance_details['state']

        if time_elapsed >= 120:
            await ctx.send("Reached timeout of {}s. Aborting to prevent an infinite loop! Run /status if you're curious".format(timeout_value))
            break

        elif instance_state != desired_state:
            if time_check_interval == 30:
                await ctx.send("Instance state is '{}' - waiting for '{}'. Taking longer than usual.. ({}s) ".format(instance_state, desired_state, time_elapsed))
            #await ctx.send("Instance state is '{}' - waiting for '{}'. Retrying in {}s. Total duration {}s ".format(instance_state, desired_state, time_check_interval, time_elapsed))
            time.sleep(time_check_interval)
            time_elapsed = time_elapsed + time_check_interval

        elif instance_state == desired_state:
            await ctx.send("Instance state is now '{}' ({}s) ".format(instance_state, time_elapsed))
            break

    #await ctx.send("Instance is now {}".format(instance_state))

@slash.slash(name="stop",
             guild_ids=guild_id,
             description = "Stop VM"
             )
async def _stop(ctx): # Defines a new "context" (ctx) command called "stop."
    run = ec2_send_command(instance_current, 'stop')
    await ctx.send(run)

    desired_state = 'stopped'
    time_elapsed = 0
    time_check_interval = 5
    timeout_value = 120

    while True:
        # Retrieve the EC2 instance state
        instance_details = ec2_get_status(instance_current)
        instance_state = instance_details['state']

        if time_elapsed >= 120:
            await ctx.send("Reached timeout of {}s. Aborting to prevent an infinite loop! Run /status if you're curious".format(timeout_value))
            break

        elif instance_state != desired_state:
            if time_elapsed == 30:
                await ctx.send("Instance state is '{}' - waiting for '{}'. Taking longer than usual.. ({}s) ".format(instance_state, desired_state, time_elapsed))
                time.sleep(time_check_interval)
                time_elapsed = time_elapsed + time_check_interval
            #await ctx.send("Instance state is '{}' - waiting for '{}'. Retrying in {}s. Total duration {}s ".format(instance_state, desired_state, time_check_interval, time_elapsed))
            else:
                time.sleep(time_check_interval)
                time_elapsed = time_elapsed + time_check_interval

        elif instance_state == desired_state:
            await ctx.send("Instance state is now '{}' ({}s) ".format(instance_state, time_elapsed))
            break

#    await ctx.send("Instance is now {}".format(instance_state))

if __name__ == "__main__":
    bot.run(configfile["discord_bot_token"])
    
