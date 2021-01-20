#![feature(with_options)]
#![feature(array_value_iter)]

extern crate regex;
extern crate serde;
extern crate serde_yaml;

use std::collections::HashSet;
use std::fs::File;
use std::path::{Path, PathBuf};
use std::process::Command;

use regex::Regex;
use serde::ser::Error as _;
use serde_yaml as yaml;

fn find_docker_compose_file() -> Option<&'static Path> {
    let variant1 = Path::new("./docker-compose.yml");
    let variant2 = Path::new("./docker-compose.yaml");

    if variant1.exists() {
        Some(variant1)
    } else if variant2.exists() {
        Some(variant2)
    } else {
        None
    }
}


fn generate_new_compose_yaml(mut yaml: yaml::Value) -> Option<yaml::Value> {
    let services = yaml.as_mapping_mut()?
        .get_mut(&yaml::Value::from("services"))?
        .as_mapping_mut()?;

    for (_k, v) in services {
        let s = v.as_mapping_mut()?;

        let build_section = s.get(&yaml::Value::from("build"))
            .cloned();

        let new_build_section = match build_section {
            Some(yaml::Value::String(context)) => {
                let mut m = yaml::Mapping::new();
                m.insert("context".into(), context.into());
                m.insert("network".into(), "host".into());
                m
            },
            Some(yaml::Value::Mapping(mut m)) => {
                m.insert("network".into(), "host".into());
                m
            },
            _ => continue,
        };

        s.insert(yaml::Value::from("build"), yaml::Value::Mapping(new_build_section));
    }

    Some(yaml)
}


fn modify_docker_compose_file<P: AsRef<Path>>(file: P) -> Result<(), Box<dyn std::error::Error>> {
    let new_yaml = {
        let f = File::open(file.as_ref())?;
        let yaml: yaml::Value = serde_yaml::from_reader(&f)?;

        generate_new_compose_yaml(yaml)
            .ok_or_else(|| yaml::Error::custom("invalid yaml"))?
    };

    let f = File::create(file.as_ref())?;
    serde_yaml::to_writer(f, &new_yaml)?;
    Ok(())
}


fn find_docker_args() -> Result<HashSet<String>, Box<dyn std::error::Error>> {

    let output = String::from_utf8(
        Command::new("docker-compose")
            .arg("--help")
            .output()?
            .stdout)?;

    let lines = output.lines();

    let re = Regex::new("^\\s+(--?[A-Za-z-]+)(, (--?[A-Za-z-]+))? [A-Z_]+").unwrap();

    let found_args = lines
        .flat_map(|l| re.captures_iter(l))
        .flat_map(|cap| {
            match (cap.get(1), cap.get(3)) {
                (Some(m1), Some(m2)) => vec![m1.as_str().to_string(), m2.as_str().to_string()],
                (Some(m1), None) => vec![m1.as_str().to_string()],
                _ => vec![]
            }
        })
        .collect();

    Ok(found_args)
}


fn find_docker_compose_subcommands() -> Result<HashSet<String>, Box<dyn std::error::Error>> {

    let re = Regex::new("^\\s+([a-zA-Z]+)").unwrap();

    let output = String::from_utf8(
        Command::new("docker-compose")
            .arg("--help")
            .output()?
            .stdout)?;

    let lines = output.lines()
        .rev()
        .take_while(|l| *l != "Commands:");

    let found_subcommands = lines
        .flat_map(|l| re.captures_iter(l))
        .map(|cap| cap[1].to_string())
        .collect();

    Ok(found_subcommands)
}


fn extract_explicit_file_from_args() -> Option<PathBuf> {

    let args = find_docker_args().ok()?;
    let subcommands = find_docker_compose_subcommands().ok()?;

    let mut iter = std::env::args().skip(1);
    let mut is_value = false;
    while let Some(arg) = iter.next() {
        if !is_value && subcommands.contains(&arg) {
            return None;
        }

        if arg == "-f" || arg == "--file" {
            return if let Some(f) = iter.next() {
                Some(PathBuf::from(f))
            } else {
                None
            }
        }

        is_value = args.contains(&arg);
    }

    None
}


fn main() -> Result<(), Box<dyn std::error::Error>> {

    let arg_provided_file = extract_explicit_file_from_args();

    let compose_file = match &arg_provided_file {
        Some(f) => Some(Path::new(f)),
        _ => find_docker_compose_file(),
    };

    match compose_file {
        Some(compose_file) => modify_docker_compose_file(compose_file)?,
        None => eprintln!("ERROR:  could not find compose file, continuing with docker-compose"),
    }

    let exit_status = std::process::Command::new("docker-compose")
        .args(std::env::args().skip(1))
        .spawn()?
        .wait()?;

    #[cfg(unix)] {
        use std::os::unix::process::ExitStatusExt;

        match exit_status.code() {
            Some(code) => std::process::exit(code),
            None => std::process::exit(128 + exit_status.signal().unwrap())
        }
    }

    #[cfg(not(unix))] {
        std::process::exit(exit_status.code().unwrap());
    }
}
