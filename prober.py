from easysnmp import Session
import sys
import time

def initialize_session():
    ses = sys.argv[1].split(":")
    return Session(
        hostname=ses[0],
        remote_port=ses[1],
        community=ses[2],
        version=2,
        timeout=1,
        retries=1
    )

def get_oids():
    oids = ['1.3.6.1.2.1.1.3.0']
    return oids + sys.argv[4:]

def retrieve_samples(session, oids, sampling_frequency, num_samples):
    previous_values = []
    previous_timestamps = []
    data_rates = []

    for i in range(num_samples + 1):
        current_timestamp = time.time()
        snmp_data = session.get(oids)
        current_values = []
        current_timestamps = []
        current_data_rates = []

        for f in range(len(oids)):
            if snmp_data[f].value != 'NOSUCHINSTANCE':
                current_values.append(int(snmp_data[f].value))
                current_timestamps.append(current_timestamp)

        if i > 0 and len(previous_values) > 0:
            for j in range(1, len(snmp_data)):
                if current_values[j - 1] - previous_values[j - 1] < 0:
                    snmp_type = snmp_data[j].snmp_type
                    if snmp_type == 'COUNTER':
                        current_values[j - 1] = current_values[j - 1] + 2 ** 32
                    elif snmp_type == 'COUNTER64':
                        current_values[j - 1] = current_values[j - 1] + 2 ** 64

                numerator = current_values[j - 1] - previous_values[j - 1]
                time_difference = round(current_timestamps[j - 1] - previous_timestamps[j - 1], 1)
                current_data_rates.append(int(numerator / time_difference))

        if len(current_data_rates) == len(snmp_data) - 1:
            formatted_data_rates = "|".join(str(rate) for rate in current_data_rates)
            print(int(current_timestamp), "|", formatted_data_rates)

        final_timestamp = time.time()
        time.sleep((1 / sampling_frequency) - (final_timestamp - current_timestamp))
        previous_values = current_values
        previous_timestamps = current_timestamps
        data_rates = current_data_rates

def main():
    session = initialize_session()
    oids = get_oids()
    sampling_frequency = float(sys.argv[2])
    num_samples = int(sys.argv[3])
    retrieve_samples(session, oids, sampling_frequency, num_samples)

if __name__ == '__main__':
    main()
